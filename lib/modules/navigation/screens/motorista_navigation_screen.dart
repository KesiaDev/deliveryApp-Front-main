import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/modules/tracking/services/tracking_service.dart';

// ─── Modelo de passo da rota ──────────────────────────────────────────────────

class _Step {
  final String instruction;
  final String distance;
  final double endLat;
  final double endLng;
  final String maneuver;

  const _Step({
    required this.instruction,
    required this.distance,
    required this.endLat,
    required this.endLng,
    required this.maneuver,
  });
}

// ─── Widget principal ─────────────────────────────────────────────────────────

/// Navegação turn-by-turn 100% dentro do app.
/// - Câmera inclinada (45°) seguindo o motorista na direção do deslocamento
/// - Rota vermelha desenhada via Google Directions API
/// - Painel superior com instrução atual + ícone de manobra
/// - Painel inferior com distância total restante e ETA
/// - Publica posição no Firestore em tempo real (empresa acompanha)
class MotoristaNavigationScreen extends StatefulWidget {
  final String corridaId;
  final double destinationLat;
  final double destinationLng;
  final String destinationTitle;
  final String destinationType; // 'pickup' | 'delivery'

  /// Texto do botão de confirmação ao chegar (ex: "Retirei o pedido!", "Entrega realizada!")
  final String actionLabel;

  /// Chamado quando o motorista confirma a chegada/entrega.
  /// Se null, o botão não aparece.
  final Future<void> Function()? onArrived;

  const MotoristaNavigationScreen({
    Key? key,
    required this.corridaId,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationTitle,
    this.destinationType = 'delivery',
    this.actionLabel = 'Confirmar chegada',
    this.onArrived,
  }) : super(key: key);

  @override
  State<MotoristaNavigationScreen> createState() =>
      _MotoristaNavigationScreenState();
}

class _MotoristaNavigationScreenState
    extends State<MotoristaNavigationScreen> {
  // ── Cores ──
  static const _red = Color(0xFFE53935);
  static const _routeBlue = Color(0xFF1A73E8);   // azul Google Maps
  static const _routeShadow = Color(0xFF0D47A1); // borda mais escura
  static const _green = Color(0xFF43A047);
  static const _orange = Color(0xFFFB8C00);
  static const _bg = Color(0xFF1A1A2E);
  static const _cardBg = Color(0xFF16213E);
  static const _textLight = Colors.white;
  static const _subLight = Color(0xFFB0BEC5);

  // ── Mapa ──
  GoogleMapController? _mapCtrl;
  final Set<Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};

  // ── GPS ──
  StreamSubscription<Position>? _gpsSub;
  LatLng? _pos;
  LatLng? _prevPos;
  double _bearing = 0;

  // ── Rota ──
  List<_Step> _steps = [];
  int _stepIdx = 0;
  String _totalDist = '';
  String _totalEta = '';
  bool _routeLoading = false;
  bool _arrived = false;
  bool _confirmingArrival = false;
  int _positionCount = 0;           // contagem de updates GPS
  LatLng? _lastRouteOrigin;         // origem da última rota calculada

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _startGps();
  }

  // ── GPS ───────────────────────────────────────────────────────────────────

  Future<void> _startGps() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _snack('Ative o GPS do dispositivo.');
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _snack('Permissão de localização necessária.');
      return;
    }

    // Inicia publicação Firestore (empresa acompanha)
    try {
      await TrackingService.startTracking(
        corridaId: widget.corridaId,
        userId: ApiBaseHelper.userSessao?.codUsuario?.toString() ?? '',
        updateInterval: const Duration(seconds: 5),
      );
    } catch (_) {}

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
  }

  void _onPosition(Position pos) {
    if (!mounted) return;
    final ll = LatLng(pos.latitude, pos.longitude);

    // Bearing: ângulo em relação à posição anterior
    if (_prevPos != null) {
      _bearing = _calcBearing(_prevPos!, ll);
    } else if (pos.heading > 0) {
      _bearing = pos.heading;
    }
    _prevPos = ll;

    setState(() {
      _pos = ll;
      _buildMarkers();
    });

    _positionCount++;

    if (!_routeLoading && _steps.isEmpty) {
      // Primeira posição → busca rota
      _loadRoute(ll);
    } else if (_steps.isNotEmpty) {
      _checkStepAdvance(ll);
      // Recalcula a cada 30 updates GPS se o motorista desviou >120m da rota
      if (_positionCount % 30 == 0 && _lastRouteOrigin != null) {
        final desvio = _metersBetween(
          ll.latitude, ll.longitude,
          _lastRouteOrigin!.latitude, _lastRouteOrigin!.longitude,
        );
        if (desvio > 120) {
          _steps = [];
          _loadRoute(ll);
        }
      }
    }

    // Câmera inclinada seguindo o motorista
    if (!mounted || _mapCtrl == null) return;
    _mapCtrl!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: ll,
          zoom: 17.5,
          tilt: 50,
          bearing: _bearing,
        ),
      ),
    );
  }

  // ── Rota via Directions API ──────────────────────────────────────────────

  Future<void> _loadRoute(LatLng origin) async {
    if (_routeLoading) return;
    _routeLoading = true;
    try {
      final resp = await Dio().get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination':
              '${widget.destinationLat},${widget.destinationLng}',
          'mode': 'driving',
          'language': 'pt-BR',
          'key': ApiBaseHelper.GEO_KEY,
        },
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      final data = resp.data as Map<String, dynamic>;
      if (data['status'] != 'OK' || (data['routes'] as List).isEmpty) {
        _fallbackPolyline(origin);
        return;
      }

      final route = (data['routes'] as List).first as Map<String, dynamic>;
      final leg = (route['legs'] as List).first as Map<String, dynamic>;

      // Passos
      final steps = (leg['steps'] as List).map((s) {
        final m = s as Map<String, dynamic>;
        return _Step(
          instruction: _stripHtml(m['html_instructions'] as String? ?? ''),
          distance: (m['distance'] as Map?)?['text'] as String? ?? '',
          endLat: (m['end_location'] as Map)['lat'] as double,
          endLng: (m['end_location'] as Map)['lng'] as double,
          maneuver: m['maneuver'] as String? ?? 'straight',
        );
      }).toList();

      // Polilinha
      final encoded =
          (route['overview_polyline'] as Map)['points'] as String;
      final pts = _decodePolyline(encoded);

      if (!mounted) return;
      _lastRouteOrigin = origin;
      setState(() {
        _steps = steps;
        _stepIdx = 0;
        _totalDist = (leg['distance'] as Map?)?['text'] as String? ?? '';
        _totalEta = (leg['duration'] as Map?)?['text'] as String? ?? '';
        _drawPolylines(pts);
      });
    } catch (e) {
      _fallbackPolyline(origin);
    } finally {
      _routeLoading = false;
    }
  }

  /// Desenha sombra + linha azul por cima (efeito Google Maps)
  void _drawPolylines(List<LatLng> pts) {
    _polylines.clear();
    // Sombra/borda mais escura e larga
    _polylines[const PolylineId('shadow')] = Polyline(
      polylineId: const PolylineId('shadow'),
      points: pts,
      color: _routeShadow,
      width: 12,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      zIndex: 1,
    );
    // Linha principal azul
    _polylines[const PolylineId('r')] = Polyline(
      polylineId: const PolylineId('r'),
      points: pts,
      color: _routeBlue,
      width: 8,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      zIndex: 2,
    );
  }

  void _fallbackPolyline(LatLng origin) {
    if (!mounted) return;
    final dest = LatLng(widget.destinationLat, widget.destinationLng);
    final pts = [origin, dest];
    setState(() => _drawPolylines(pts));
  }

  // ── Avanço de passos ─────────────────────────────────────────────────────

  void _checkStepAdvance(LatLng pos) {
    if (_steps.isEmpty || _stepIdx >= _steps.length) return;
    final step = _steps[_stepIdx];
    final dist = _metersBetween(
        pos.latitude, pos.longitude, step.endLat, step.endLng);
    if (dist < 40) {
      if (_stepIdx < _steps.length - 1) {
        setState(() => _stepIdx++);
      } else {
        setState(() => _arrived = true);
      }
    }
  }

  // ── Marcadores ───────────────────────────────────────────────────────────

  void _buildMarkers() {
    _markers.clear();
    if (_pos != null) {
      _markers.add(Marker(
        markerId: const MarkerId('moto'),
        position: _pos!,
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        flat: true,
        rotation: _bearing,
        zIndex: 3,
      ));
    }
    _markers.add(Marker(
      markerId: const MarkerId('dest'),
      position: LatLng(widget.destinationLat, widget.destinationLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        widget.destinationType == 'pickup'
            ? BitmapDescriptor.hueGreen
            : BitmapDescriptor.hueOrange,
      ),
      infoWindow: InfoWindow(title: widget.destinationTitle),
      zIndex: 2,
    ));
  }

  // ── Decode de polilinha Google Encoded Polyline ──────────────────────────

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  // ── Helpers matemáticos ──────────────────────────────────────────────────

  double _calcBearing(LatLng from, LatLng to) {
    final dLng = (to.longitude - from.longitude) * pi / 180;
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  double _metersBetween(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double? _distKmToDestination() {
    if (_pos == null) return null;
    return _metersBetween(_pos!.latitude, _pos!.longitude,
            widget.destinationLat, widget.destinationLng) /
        1000;
  }

  String _fmtDist(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll('  ', ' ').trim();

  IconData _maneuverIcon(String m) {
    if (m.contains('right')) return Icons.turn_right_rounded;
    if (m.contains('left')) return Icons.turn_left_rounded;
    if (m.contains('uturn')) return Icons.u_turn_left_rounded;
    if (m.contains('roundabout')) return Icons.roundabout_right_rounded;
    if (m.contains('ramp')) return Icons.fork_right_rounded;
    if (m.contains('merge')) return Icons.merge_rounded;
    return Icons.straight_rounded;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _gpsSub = null;
    // NÃO chamar _mapCtrl?.dispose() — causa tela preta na volta.
    // O GoogleMap widget gerencia o ciclo de vida do controller internamente.
    _mapCtrl = null;
    TrackingService.stopTracking();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isPickup = widget.destinationType == 'pickup';
    final accentColor = isPickup ? _green : _orange;
    final distKm = _distKmToDestination();
    final step = _steps.isNotEmpty && _stepIdx < _steps.length
        ? _steps[_stepIdx]
        : null;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── MAPA ─────────────────────────────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.destinationLat, widget.destinationLng),
                zoom: 15,
              ),
              markers: _markers,
              polylines: _polylines.values.toSet(),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              compassEnabled: true,
              tiltGesturesEnabled: true,
              onMapCreated: (c) {
                _mapCtrl = c;
                _buildMarkers();
              },
            ),
          ),

          // ── PAINEL SUPERIOR: instrução atual ─────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _arrived
                  ? _arrivedBanner(accentColor)
                  : step != null
                      ? _stepBanner(step, accentColor)
                      : _loadingBanner(),
            ),
          ),

          // ── BOTÃO VOLTAR ─────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Material(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),

          // ── PAINEL INFERIOR: distância + ETA ─────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _bottomPanel(distKm, accentColor),
          ),

          // Loading inicial
          if (_pos == null)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _stepBanner(_Step step, Color accent) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _maneuverIcon(step.maneuver),
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instruction,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (step.distance.isNotEmpty)
                  Text(
                    step.distance,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: _subLight),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Calculando rota...',
            style: GoogleFonts.poppins(fontSize: 14, color: _subLight),
          ),
        ],
      ),
    );
  }

  Widget _arrivedBanner(Color accent) {
    final msg = widget.destinationType == 'pickup'
        ? 'Você chegou ao local de retirada!'
        : 'Você chegou ao destino da entrega!';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Banner de chegada
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg,
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Botão de confirmação
        if (widget.onArrived != null)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmingArrival ? null : _onConfirmArrival,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              icon: _confirmingArrival
                  ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: accent, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 22),
              label: Text(
                _confirmingArrival ? 'Confirmando...' : widget.actionLabel,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );

  }

  Future<void> _onConfirmArrival() async {
    if (_confirmingArrival || widget.onArrived == null) return;
    setState(() => _confirmingArrival = true);
    try {
      await widget.onArrived!();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _confirmingArrival = false);
        _snack('Erro ao confirmar. Tente novamente.');
      }
    }
  }

  Widget _bottomPanel(double? distKm, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black38, blurRadius: 16, offset: Offset(0, -4))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Distância restante
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Distância',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _subLight)),
                  Text(
                    distKm != null ? _fmtDist(distKm) : '--',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textLight,
                    ),
                  ),
                ],
              ),
              // ETA
              if (_totalEta.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Chegada aprox.',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: _subLight)),
                    Text(
                      _totalEta,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: _green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                _pos != null
                    ? 'GPS ativo · posição sendo transmitida'
                    : 'Aguardando GPS...',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: _subLight),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Destino
          Row(
            children: [
              Icon(
                widget.destinationType == 'pickup'
                    ? Icons.store_rounded
                    : Icons.location_on_rounded,
                size: 14,
                color: accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.destinationTitle,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: _subLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
