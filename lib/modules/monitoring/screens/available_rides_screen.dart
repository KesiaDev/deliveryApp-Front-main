import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../models/live_ride_model.dart';
import '../services/live_ride_service.dart';
import 'live_ride_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../bussiness/service/user_service.dart';
import '../../../bussiness/service/ApiBaseHelper.dart';
import '../../../motorista/corridas/batch/batch_service.dart';
import '../../../motorista/corridas/batch/batch_offer_screen.dart';

/// Tela do MOTORISTA — mapa com corridas disponíveis ao redor (estilo Uber)
class AvailableRidesScreen extends StatefulWidget {
  final String motoristaId;
  final String motoristaName;

  const AvailableRidesScreen({
    Key? key,
    required this.motoristaId,
    required this.motoristaName,
  }) : super(key: key);

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  static const _red = Color(0xFFE53935);
  static const _bg = Color(0xFFF7F5FA);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF757575);

  static const double _maxRadiusKm = 25.0; // raio_busca_corridas

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  List<LiveRideModel> _availableRides = [];
  StreamSubscription? _ridesSub;
  final Set<String> _dismissedRideIds = {}; // corridas ignoradas por este motorista

  double _driverLat = -23.5505;
  double _driverLng = -46.6333;
  bool _locating = true;
  bool _accepting = false;

  static const _prefKey = 'dismissed_rides';

  @override
  void initState() {
    super.initState();
    _loadDismissed();
    _getLocation();
    _listenRides();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefKey) ?? [];
    if (mounted) setState(() => _dismissedRideIds.addAll(saved));
  }

  Future<void> _saveDismissed(String rideId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefKey) ?? [];
    if (!saved.contains(rideId)) {
      saved.add(rideId);
      // Manter apenas os últimos 100 para não crescer indefinidamente
      if (saved.length > 100) saved.removeRange(0, saved.length - 100);
      await prefs.setStringList(_prefKey, saved);
    }
  }

  Future<void> _getLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _driverLat = pos.latitude;
        _driverLng = pos.longitude;
        _locating = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(_driverLat, _driverLng), 14));
      _updateMarkers();
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _listenRides() {
    _ridesSub = LiveRideService.listenToAvailableRides().listen((rides) {
      if (!mounted) return;
      // Filter: within radius AND not dismissed by this motorista
      final filtered = rides.where((r) {
        if (_dismissedRideIds.contains(r.rideId)) return false;
        return _distanceTo(r.pickupLat, r.pickupLng) <= _maxRadiusKm;
      }).toList();
      setState(() => _availableRides = filtered);
      _updateMarkers();
    });
  }

  void _updateMarkers() {
    _markers.clear();

    // Marcador do motorista
    _markers.add(Marker(
      markerId: const MarkerId('driver'),
      position: LatLng(_driverLat, _driverLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: InfoWindow(title: '🛵 ${widget.motoristaName}', snippet: 'Você'),
      zIndex: 3,
    ));

    // Marcadores das corridas disponíveis
    for (final ride in _availableRides) {
      final distKm = _distanceTo(ride.pickupLat, ride.pickupLng);
      _markers.add(Marker(
        markerId: MarkerId('ride_${ride.rideId}'),
        position: LatLng(ride.pickupLat, ride.pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: '📦 ${ride.pickupName}',
          snippet: '${distKm.toStringAsFixed(1)}km • R\$ ${ride.price.toStringAsFixed(0)}',
        ),
        onTap: () => _showRideDetails(ride),
        zIndex: 2,
      ));
    }

    if (mounted) setState(() {});
  }

  double _distanceTo(double lat, double lng) {
    final dLat = (lat - _driverLat) * (pi / 180);
    final dLng = (lng - _driverLng) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_driverLat * pi / 180) *
            cos(lat * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return 6371 * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void _showRideDetails(LiveRideModel ride) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RideDetailSheet(
        ride: ride,
        distanceKm: _distanceTo(ride.pickupLat, ride.pickupLng),
        accepting: _accepting,
        onAccept: () => _acceptRide(ride),
        onDismiss: () {
          setState(() => _dismissedRideIds.add(ride.rideId));
          _saveDismissed(ride.rideId);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _acceptRide(LiveRideModel ride) async {
    setState(() => _accepting = true);
    try {
      // 1. Spring Boot (sistema primário) — aceita no banco PostgreSQL
      if (ride.numSeq != null) {
        await UserService().aceitarCorrida(
          ride.numSeq!,
          ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA,
        );
      }

      // 2. Firestore (tempo real, não-bloqueante) — falha silenciosa se permissão negada
      try {
        await LiveRideService.assignDriver(
          ride.rideId,
          widget.motoristaId,
          widget.motoristaName,
          _driverLat,
          _driverLng,
        );
      } catch (firestoreErr) {
        debugPrint('⚠️ Firestore assignDriver ignorado: $firestoreErr');
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // fecha bottom sheet

      // 3. Verifica candidatos para entrega agrupada (não-bloqueante, falha silenciosa)
      if (ride.numSeq != null) {
        try {
          final candidatos = await BatchService.buscarCandidatos(ride.numSeq!);
          if (candidatos.isNotEmpty && mounted) {
            await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => BatchOfferScreen(
                  group: candidatos.first,
                  corridaPrincipalId: ride.numSeq!,
                  motoristaId: int.tryParse(widget.motoristaId) ?? 0,
                ),
              ),
            );
          }
        } catch (batchErr) {
          debugPrint('⚠️ Batch check ignorado: $batchErr');
        }
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveRideMapScreen(
            rideId: ride.rideId,
            currentUserId: widget.motoristaId,
            currentUserName: widget.motoristaName,
            currentUserType: 'motorista',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao aceitar: $e')));
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  void dispose() {
    _ridesSub?.cancel();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                  color: Colors.green, shape: BoxShape.circle),
            ),
            Text(
              'Online — Buscando corridas',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ── MAPA ────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
                target: LatLng(_driverLat, _driverLng), zoom: 14),
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (c) {
              _mapController = c;
              if (!_locating) {
                c.animateCamera(CameraUpdate.newLatLngZoom(
                    LatLng(_driverLat, _driverLng), 14));
              }
            },
          ),

          // Loading de localização
          if (_locating)
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6)
                    ]),
                child: Row(
                  children: [
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFE53935))),
                    const SizedBox(width: 8),
                    Text('Localizando...',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: _textSecondary)),
                  ],
                ),
              ),
            ),

          // ── Bottom: lista de corridas ────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              constraints:
                  BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '${_availableRides.length} corrida${_availableRides.length != 1 ? 's' : ''} disponível${_availableRides.length != 1 ? 'is' : ''}',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary),
                        ),
                        const Spacer(),
                        if (_availableRides.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Toque no mapa para ver',
                                style: GoogleFonts.poppins(
                                    fontSize: 10, color: _red)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_availableRides.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      child: Column(
                        children: [
                          Icon(Icons.motorcycle_rounded,
                              size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('Nenhuma corrida disponível no momento',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: _textSecondary),
                              textAlign: TextAlign.center),
                          Text('Aguarde novas solicitações...',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey.shade400)),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        itemCount: _availableRides.length,
                        itemBuilder: (_, i) {
                          final ride = _availableRides[i];
                          final dist =
                              _distanceTo(ride.pickupLat, ride.pickupLng);
                          return _RideCard(
                            ride: ride,
                            distanceKm: dist,
                            onTap: () => _showRideDetails(ride),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet de detalhes de corrida ──────────────────────────────────────

class _RideDetailSheet extends StatelessWidget {
  final LiveRideModel ride;
  final double distanceKm;
  final bool accepting;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  static const _red = Color(0xFFE53935);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF757575);

  const _RideDetailSheet({
    required this.ride,
    required this.distanceKm,
    required this.accepting,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, -8))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),

          // Header: loja + distância ao motoboy
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.store_mall_directory_rounded,
                    color: Colors.orange.shade700, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.pickupName,
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary)),
                    Text(ride.pickupAddress,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: _textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${distanceKm.toStringAsFixed(1)} km',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary)),
                  Text('de você',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: _textSecondary)),
                ],
              ),
            ],
          ),

          const Divider(height: 20),

          // Rota
          _InfoRow(
              icon: Icons.location_on_rounded,
              color: Colors.green,
              label: 'Entregar para',
              value: ride.deliveryClientName,
              subtitle: ride.deliveryAddress),
          const SizedBox(height: 8),
          _InfoRow(
              icon: Icons.straighten_rounded,
              color: Colors.blue,
              label: 'Distância de entrega',
              value: '${ride.distanceKm.toStringAsFixed(1)} km'),
          const SizedBox(height: 8),
          _InfoRow(
              icon: Icons.payments_rounded,
              color: Colors.green.shade700,
              label: 'Valor',
              value: 'R\$ ${ride.price.toStringAsFixed(2)}'),
          if (ride.notes != null && ride.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
                icon: Icons.notes_rounded,
                color: Colors.grey,
                label: 'Obs',
                value: ride.notes!),
          ],

          const SizedBox(height: 16),

          // Forma de pagamento
          Row(
            children: [
              Icon(_payIcon(ride.paymentType),
                  size: 16, color: _textSecondary),
              const SizedBox(width: 4),
              Text(
                  _payLabel(ride.paymentType),
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: _textSecondary)),
            ],
          ),

          const SizedBox(height: 20),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSecondary,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Ignorar',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: accepting ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: accepting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 20),
                            const SizedBox(width: 6),
                            Text('Aceitar corrida',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _payIcon(String type) {
    switch (type) {
      case 'pix':
        return Icons.pix;
      case 'cartao':
        return Icons.credit_card_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  String _payLabel(String type) {
    switch (type) {
      case 'pix':
        return 'Pagamento via PIX';
      case 'cartao':
        return 'Pagamento em Cartão';
      default:
        return 'Pagamento em Dinheiro';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? subtitle;
  const _InfoRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: const Color(0xFF757575))),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A)),
                  overflow: TextOverflow.ellipsis),
              if (subtitle != null)
                Text(subtitle!,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: const Color(0xFF757575)),
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _RideCard extends StatelessWidget {
  final LiveRideModel ride;
  final double distanceKm;
  final VoidCallback onTap;
  static const _red = Color(0xFFE53935);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF757575);

  const _RideCard(
      {required this.ride,
      required this.distanceKm,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.store_mall_directory_rounded,
                  color: Colors.orange.shade700, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ride.pickupName,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary),
                      overflow: TextOverflow.ellipsis),
                  Text('→ ${ride.deliveryClientName}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _textSecondary),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('R\$ ${ride.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _red)),
                Text('${distanceKm.toStringAsFixed(1)}km de você',
                    style:
                        GoogleFonts.poppins(fontSize: 10, color: _textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
