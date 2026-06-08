import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/location_update_model.dart';
import '../services/tracking_service.dart';
import 'package:flutter/foundation.dart';

/// Tela de rastreamento em tempo real — visão EMPRESA/CLIENTE
/// Mostra: marker motorista (tempo real), pickup (retirada), delivery (entrega)
/// Status timeline + ETA calculado
class LiveTrackingScreen extends StatefulWidget {
  final String corridaId;
  final String trackedUserId;
  final double initialLatitude;
  final double initialLongitude;

  // Dados extras opcionais para enriquecer a tela
  final double? pickupLat;
  final double? pickupLng;
  final String? pickupLabel;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? deliveryLabel;
  final String? motoristaName;
  final int? statusCorrida; // 0=aguardando,1=aceita,2=em andamento,3=concluída

  const LiveTrackingScreen({
    Key? key,
    required this.corridaId,
    required this.trackedUserId,
    required this.initialLatitude,
    required this.initialLongitude,
    this.pickupLat,
    this.pickupLng,
    this.pickupLabel,
    this.deliveryLat,
    this.deliveryLng,
    this.deliveryLabel,
    this.motoristaName,
    this.statusCorrida,
  }) : super(key: key);

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  static const _red = Color(0xFFE53935);
  static const _bg = Color(0xFFF7F5FA);
  static const _card = Colors.white;
  static const _text = Color(0xFF1A1A1A);
  static const _sub = Color(0xFF757575);
  static const _green = Color(0xFF43A047);
  static const _orange = Color(0xFFFB8C00);

  GoogleMapController? _mapController;
  LocationUpdateModel? _currentLocation;
  final Set<Marker> _markers = {};
  StreamSubscription? _firestoreSub;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  Future<void> _initTracking() async {
    // Tenta última posição do Firestore primeiro
    final last = await TrackingService.getLastLocationFromFirestore(widget.corridaId);
    if (last != null && mounted) {
      setState(() {
        _currentLocation = last;
        _refreshMarkers();
      });
    } else if (widget.initialLatitude != 0.0 && widget.initialLongitude != 0.0) {
      setState(() {
        _currentLocation = LocationUpdateModel(
          id: 'initial',
          corridaId: widget.corridaId,
          userId: widget.trackedUserId,
          latitude: widget.initialLatitude,
          longitude: widget.initialLongitude,
          timestamp: DateTime.now(),
        );
        _refreshMarkers();
      });
    }

    TrackingService.addLocationListener(_onUpdate);
    _firestoreSub = TrackingService.listenToLocationUpdates(
      widget.corridaId,
      _onUpdate,
    );
  }

  void _onUpdate(LocationUpdateModel update) {
    if (update.userId == widget.trackedUserId && mounted) {
      setState(() {
        _currentLocation = update;
        _refreshMarkers();
        _moveCamera();
      });
    }
  }

  void _refreshMarkers() {
    _markers.clear();

    // Marker do motorista (azul, move em tempo real)
    if (_currentLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('motorista'),
        position: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: _currentLocation!.heading ?? 0.0,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: widget.motoristaName ?? 'Motoboy',
          snippet: _currentLocation!.speed != null
              ? '${(_currentLocation!.speed! * 3.6).toStringAsFixed(0)} km/h'
              : 'Em movimento',
        ),
        zIndex: 3,
      ));
    }

    // Marker de retirada (verde — loja/empresa)
    if (widget.pickupLat != null && widget.pickupLng != null) {
      _markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.pickupLat!, widget.pickupLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: '📦 Retirada',
          snippet: widget.pickupLabel ?? 'Local de retirada',
        ),
        zIndex: 2,
      ));
    }

    // Marker de entrega (laranja — destino do cliente)
    if (widget.deliveryLat != null && widget.deliveryLng != null) {
      _markers.add(Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(widget.deliveryLat!, widget.deliveryLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: '🏠 Entrega',
          snippet: widget.deliveryLabel ?? 'Endereço de entrega',
        ),
        zIndex: 2,
      ));
    }
  }

  void _moveCamera() {
    if (_mapController != null && _currentLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        ),
      );
    }
  }

  /// Calcula distância Haversine em km entre dois pontos
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// ETA em minutos até o próximo destino relevante
  String? _calcEta() {
    if (_currentLocation == null) return null;

    // Próximo destino: pickup se status ≤ 1, delivery se status ≥ 2
    final goingToPickup = (widget.statusCorrida ?? 0) <= 1;
    double? destLat = goingToPickup ? widget.pickupLat : widget.deliveryLat;
    double? destLng = goingToPickup ? widget.pickupLng : widget.deliveryLng;

    if (destLat == null || destLng == null) {
      destLat = widget.deliveryLat;
      destLng = widget.deliveryLng;
      if (destLat == null || destLng == null) return null;
    }

    final distKm = _distanceKm(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      destLat,
      destLng,
    );

    // Velocidade: usa GPS se disponível, senão 30 km/h de média urbana
    final speedKmh = (_currentLocation!.speed != null && _currentLocation!.speed! > 1)
        ? (_currentLocation!.speed! * 3.6)
        : 30.0;

    final etaMin = (distKm / speedKmh * 60).round();

    if (etaMin <= 0) return 'Chegando';
    if (etaMin < 60) return '~$etaMin min';
    final h = etaMin ~/ 60;
    final m = etaMin % 60;
    return '~${h}h${m > 0 ? '${m}min' : ''}';
  }

  @override
  void dispose() {
    TrackingService.removeLocationListener(_onUpdate);
    _firestoreSub?.cancel();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eta = _calcEta();
    final status = widget.statusCorrida ?? 0;
    final hasLocation = _currentLocation != null;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'Acompanhar entrega',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _text,
          ),
        ),
        backgroundColor: _card,
        elevation: 0,
        iconTheme: const IconThemeData(color: _text),
        actions: [
          if (hasLocation)
            IconButton(
              icon: const Icon(Icons.my_location_rounded, color: _red),
              tooltip: 'Centralizar motoboy',
              onPressed: _moveCamera,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentLocation?.latitude ?? widget.initialLatitude,
                _currentLocation?.longitude ?? widget.initialLongitude,
              ),
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (c) {
              _mapController = c;
              if (hasLocation) _moveCamera();
            },
          ),

          // Legenda dos marcadores
          if (widget.pickupLat != null || widget.deliveryLat != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _card.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.pickupLat != null) _legendItem(Colors.green, '📦 Retirada'),
                    if (widget.deliveryLat != null) ...[
                      const SizedBox(height: 2),
                      _legendItem(_orange, '🏠 Entrega'),
                    ],
                    const SizedBox(height: 2),
                    _legendItem(Colors.blue.shade400, '🛵 Motoboy'),
                  ],
                ),
              ),
            ),

          // Card inferior com info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -3))],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status timeline
                  _StatusTimeline(status: status),
                  const SizedBox(height: 16),

                  // Linha: motorista + ETA
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.motorcycle_rounded, color: _red, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.motoristaName ?? 'Motoboy',
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _text),
                            ),
                            if (_currentLocation?.speed != null)
                              Text(
                                '${(_currentLocation!.speed! * 3.6).toStringAsFixed(0)} km/h',
                                style: GoogleFonts.poppins(fontSize: 12, color: _sub),
                              ),
                          ],
                        ),
                      ),
                      if (eta != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Chegada em', style: GoogleFonts.poppins(fontSize: 11, color: _sub)),
                            Text(
                              eta,
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _red),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Linha: última atualização
                  if (_currentLocation != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rastreamento ativo · ${_formatTime(_currentLocation!.timestamp)}',
                          style: GoogleFonts.poppins(fontSize: 11, color: _sub),
                        ),
                      ],
                    ),
                  ],

                  // Destino da entrega
                  if (widget.deliveryLabel != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: _orange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.deliveryLabel!,
                            style: GoogleFonts.poppins(fontSize: 12, color: _sub),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Loading se não tiver localização ainda
          if (!hasLocation)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: _text)),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
    return '${diff.inHours}h atrás';
  }
}

/// Timeline visual de progresso da corrida
class _StatusTimeline extends StatelessWidget {
  final int status; // Spring Boot: 0=aguardando,1=aceita,2=em andamento,3=concluída

  const _StatusTimeline({required this.status});

  static const _icons = [
    Icons.hourglass_empty_rounded,
    Icons.check_circle_rounded,
    Icons.directions_bike_rounded,
    Icons.done_all_rounded,
  ];
  static const _labels = ['Aguardando', 'Aceito', 'A caminho', 'Entregue'];

  static const _red = Color(0xFFE53935);
  static const _sub = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_icons.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Linha conectora entre steps
          final stepIndex = i ~/ 2;
          final active = status > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: active ? _red : _sub,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final done = status >= stepIndex;
        final current = status == stepIndex;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: current ? 32 : 26,
              height: current ? 32 : 26,
              decoration: BoxDecoration(
                color: done ? _red : _sub.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: current
                    ? [BoxShadow(color: _red.withOpacity(0.35), blurRadius: 8)]
                    : [],
              ),
              child: Icon(
                _icons[stepIndex],
                size: current ? 18 : 14,
                color: done ? Colors.white : _sub,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _labels[stepIndex],
              style: TextStyle(
                fontSize: 9,
                fontWeight: current ? FontWeight.w700 : FontWeight.normal,
                color: done ? _red : _sub,
              ),
            ),
          ],
        );
      }),
    );
  }
}
