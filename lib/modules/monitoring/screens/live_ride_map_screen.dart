import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/modules/chat/screens/chat_screen.dart';
import '../models/live_ride_model.dart';
import '../services/live_ride_service.dart';

/// Tela unificada de corrida ao vivo — usada por EMPRESA, MOTORISTA e ADMIN
/// currentUserType: 'empresa' | 'motorista' | 'admin'
class LiveRideMapScreen extends StatefulWidget {
  final String rideId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserType; // empresa | motorista | admin

  const LiveRideMapScreen({
    Key? key,
    required this.rideId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserType,
  }) : super(key: key);

  @override
  State<LiveRideMapScreen> createState() => _LiveRideMapScreenState();
}

class _LiveRideMapScreenState extends State<LiveRideMapScreen>
    with TickerProviderStateMixin {
  static const _red = Color(0xFFE53935);
  static const _bg = Color(0xFFF7F5FA);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF757575);

  LiveRideModel? _ride;
  StreamSubscription? _rideSub;
  StreamSubscription<Position>? _gpsSub;
  GoogleMapController? _mapController;
  late TabController _tabCtrl;

  final Set<Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};

  bool _mapExpanded = false;
  bool _updatingStatus = false;

  // Motorcycle smooth animation
  LatLng? _motoDisplayPos;
  LatLng? _motoFromPos;
  LatLng? _motoTargetPos;
  AnimationController? _motoAnimCtrl;
  Animation<double>? _motoAnim;
  BitmapDescriptor? _motoIcon;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _motoAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _motoAnim = CurvedAnimation(parent: _motoAnimCtrl!, curve: Curves.easeInOut);
    _motoAnimCtrl!.addListener(_onMotoAnimTick);
    _buildMotoIcon().then((icon) {
      if (mounted) setState(() => _motoIcon = icon);
    });
    _listenToRide();
    if (widget.currentUserType == 'motorista') _startGPS();
  }

  void _onMotoAnimTick() {
    final from = _motoFromPos;
    final to = _motoTargetPos;
    final t = _motoAnim?.value ?? 0;
    if (from != null && to != null) {
      _motoDisplayPos = LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      );
      _rebuildMotoMarker();
    }
  }

  void _rebuildMotoMarker() {
    final pos = _motoDisplayPos;
    final ride = _ride;
    if (pos == null || ride == null || !mounted) return;
    _markers.removeWhere((m) => m.markerId.value == 'motorista');
    _markers.add(Marker(
      markerId: const MarkerId('motorista'),
      position: pos,
      icon: _motoIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: '🛵 ${ride.motoristaName ?? 'Motorista'}',
        snippet: _getPhaseLabel(ride),
      ),
      anchor: const Offset(0.5, 0.5),
      zIndexInt: 2,
    ));
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _buildMotoIcon() async {
    const size = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(size / 2 + 2, size / 2 + 4), 30, shadowPaint);

    // Circle background
    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size / 2, size / 2),
        30,
        [const Color(0xFFFF4444), const Color(0xFFB71C1C)],
      );
    canvas.drawCircle(Offset(size / 2, size / 2), 30, bgPaint);

    // White ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(size / 2, size / 2), 28, ringPaint);

    // Motorcycle emoji
    final tp = TextPainter(
      text: const TextSpan(text: '🛵', style: TextStyle(fontSize: 30)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2 - 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    return BitmapDescriptor.bytes(data.buffer.asUint8List());
  }

  Future<void> _startGPS() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) await Geolocator.requestPermission();
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      LiveRideService.updateDriverLocation(
          widget.rideId, pos.latitude, pos.longitude);
    });
  }

  // Mapeia status Firestore → status PostgreSQL
  int? _pgStatus(int firestoreStatus) {
    switch (firestoreStatus) {
      case 1: return ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA;
      case 2:
      case 3: return ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO;
      case 4: return ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA;
      default: return null;
    }
  }

  Future<void> _advanceStatus() async {
    final ride = _ride;
    if (ride == null || _updatingStatus) return;
    setState(() => _updatingStatus = true);
    try {
      final next = ride.status + 1;
      await LiveRideService.updateStatus(widget.rideId, next);

      // Sync ao PostgreSQL se numSeq disponível
      if (ride.numSeq != null) {
        final pgSt = _pgStatus(next);
        if (pgSt != null) {
          try {
            await UserService().finalizarChamado(ride.numSeq!, pgSt);
          } catch (_) {}
        }
      }

      if (next == 4 && mounted) {
        _gpsSub?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Row(children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Entrega concluída com sucesso!',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ]),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  String _nextActionLabel(int status) {
    switch (status) {
      case 1: return 'Cheguei na loja';
      case 2: return 'Retirei o pacote';
      case 3: return 'Entrega realizada!';
      default: return '';
    }
  }

  IconData _nextActionIcon(int status) {
    switch (status) {
      case 1: return Icons.store_rounded;
      case 2: return Icons.delivery_dining_rounded;
      case 3: return Icons.check_circle_rounded;
      default: return Icons.arrow_forward_rounded;
    }
  }

  void _listenToRide() {
    _rideSub = LiveRideService.listenToRide(widget.rideId).listen((ride) {
      if (!mounted || ride == null) return;
      final prev = _ride;
      setState(() => _ride = ride);
      _updateMap(ride, prev);
    });
  }

  Future<void> _updateMap(LiveRideModel ride, LiveRideModel? prev) async {
    _markers.clear();

    // Marcador de PICKUP
    _markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: LatLng(ride.pickupLat, ride.pickupLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(title: ride.pickupName, snippet: 'Retirada'),
    ));

    // Marcador de ENTREGA
    _markers.add(Marker(
      markerId: const MarkerId('delivery'),
      position: LatLng(ride.deliveryLat, ride.deliveryLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
          title: ride.deliveryClientName, snippet: ride.deliveryAddress),
    ));

    // Marcador do MOTORISTA (quando disponível) — com animação suave
    if (ride.motoristaLat != null && ride.motoristaLng != null) {
      final newTarget = LatLng(ride.motoristaLat!, ride.motoristaLng!);
      final hasExistingPos = _motoDisplayPos != null;

      _motoFromPos = _motoDisplayPos ?? newTarget;
      _motoTargetPos = newTarget;

      if (!hasExistingPos) {
        // Primeira posição: aparece direto sem animação
        _motoDisplayPos = newTarget;
        _rebuildMotoMarker();
      } else {
        // Posição nova: adiciona marcador na posição atual e inicia animação
        _rebuildMotoMarker();
        _motoAnimCtrl?.value = 0;
        _motoAnimCtrl?.forward();
      }

      // Rota do motorista → destino atual
      await _drawRouteForPhase(ride);

      // Anima câmera para seguir o motoboy
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
            LatLng(ride.motoristaLat!, ride.motoristaLng!)),
      );
    } else {
      // Sem motorista ainda: enquadra pickup+delivery
      _fitCamera(ride);
    }

    if (mounted) setState(() {});
  }

  Future<void> _drawRouteForPhase(LiveRideModel ride) async {
    if (ride.motoristaLat == null) return;

    final origin = PointLatLng(ride.motoristaLat!, ride.motoristaLng!);
    PointLatLng destination;

    if (ride.status <= 2) {
      // A caminho ou chegou ao local → destino é PICKUP
      destination = PointLatLng(ride.pickupLat, ride.pickupLng);
    } else {
      // Em entrega → destino é o cliente
      destination = PointLatLng(ride.deliveryLat, ride.deliveryLng);
    }

    try {
      final pp = PolylinePoints(apiKey: ApiBaseHelper.GEO_KEY);
      final result = await pp.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: origin,
          destination: destination,
          mode: TravelMode.driving,
        ),
      );
      final pts = result.points.isNotEmpty
          ? result.points.map((p) => LatLng(p.latitude, p.longitude)).toList()
          : [LatLng(origin.latitude, origin.longitude),
             LatLng(destination.latitude, destination.longitude)];

      _polylines[const PolylineId('route')] = Polyline(
        polylineId: const PolylineId('route'),
        points: pts,
        color: _red,
        width: 4,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );
    } catch (_) {
      _polylines[const PolylineId('route')] = Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(origin.latitude, origin.longitude),
          LatLng(destination.latitude, destination.longitude),
        ],
        color: _red.withOpacity(0.6),
        width: 3,
        patterns: [PatternItem.dash(10), PatternItem.gap(5)],
      );
    }
  }

  void _fitCamera(LiveRideModel ride) {
    if (_mapController == null) return;
    final minLat = min(ride.pickupLat, ride.deliveryLat);
    final maxLat = max(ride.pickupLat, ride.deliveryLat);
    final minLng = min(ride.pickupLng, ride.deliveryLng);
    final maxLng = max(ride.pickupLng, ride.deliveryLng);
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      72,
    ));
  }

  String _getPhaseLabel(LiveRideModel ride) {
    switch (ride.status) {
      case 1:
        return 'A caminho da loja';
      case 2:
        return 'Chegou! Retirando pacote';
      case 3:
        return 'Em rota de entrega';
      default:
        return 'Em movimento';
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.purple;
      case 3:
        return _red;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(int status) {
    switch (status) {
      case 0:
        return Icons.search_rounded;
      case 1:
        return Icons.motorcycle_rounded;
      case 2:
        return Icons.store_rounded;
      case 3:
        return Icons.delivery_dining_rounded;
      case 4:
        return Icons.check_circle_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  void dispose() {
    _rideSub?.cancel();
    _gpsSub?.cancel();
    _tabCtrl.dispose();
    _motoAnimCtrl?.dispose();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Corrida ao Vivo',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
            ),
            Row(children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(
                '#${widget.rideId.length > 8 ? widget.rideId.substring(0, 8) : widget.rideId}',
                style: GoogleFonts.poppins(fontSize: 11, color: _textSecondary),
              ),
            ]),
          ],
        ),
        actions: [
          if (ride != null)
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor(ride.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon(ride.status),
                      size: 14, color: _statusColor(ride.status)),
                  const SizedBox(width: 4),
                  Text(
                    ride.statusLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(ride.status)),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── MAPA ──────────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _mapExpanded = !_mapExpanded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _mapExpanded
                  ? MediaQuery.of(context).size.height * 0.6
                  : MediaQuery.of(context).size.height * 0.38,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: ride != null
                          ? LatLng(ride.pickupLat, ride.pickupLng)
                          : const LatLng(-23.5505, -46.6333),
                      zoom: 14,
                    ),
                    markers: _markers,
                    polylines: _polylines.values.toSet(),
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                    onMapCreated: (c) {
                      _mapController = c;
                      if (ride != null) _fitCamera(ride);
                    },
                  ),

                  // Chip AO VIVO
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text('AO VIVO',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),

                  // Expand hint
                  Positioned(
                    bottom: 8,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4)
                          ]),
                      child: Icon(
                        _mapExpanded
                            ? Icons.unfold_less_rounded
                            : Icons.unfold_more_rounded,
                        size: 18,
                        color: _textSecondary,
                      ),
                    ),
                  ),

                  // Card de info do motorista (quando confirmado)
                  if (ride?.motoristaName != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 48,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: _red,
                              child: Text(
                                (ride!.motoristaName?.isNotEmpty == true
                                    ? ride.motoristaName![0].toUpperCase()
                                    : '?'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(ride.motoristaName!,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _textPrimary),
                                      overflow: TextOverflow.ellipsis),
                                  Text(_getPhaseLabel(ride),
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: _statusColor(ride.status))),
                                ],
                              ),
                            ),
                            Icon(_statusIcon(ride.status),
                                size: 18, color: _statusColor(ride.status)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── PROGRESS BAR de fases ─────────────────────────────────────────
          if (ride != null && !_mapExpanded) _buildProgressBar(ride),

          // ── BOTÃO DE AÇÃO DO MOTORISTA ────────────────────────────────────
          if (!_mapExpanded &&
              widget.currentUserType == 'motorista' &&
              ride != null &&
              ride.status >= 1 &&
              ride.status <= 3)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _updatingStatus ? null : _advanceStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        ride.status == 3 ? Colors.green : _red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _updatingStatus
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Icon(_nextActionIcon(ride.status), size: 20),
                  label: Text(
                    _updatingStatus ? 'Atualizando...' : _nextActionLabel(ride.status),
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),

          // ── TABS de chat ──────────────────────────────────────────────────
          if (!_mapExpanded) ...[
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: _red,
                unselectedLabelColor: _textSecondary,
                indicatorColor: _red,
                indicatorWeight: 2.5,
                labelStyle: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_rounded, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _chatTab1Label(ride),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.admin_panel_settings_rounded,
                            size: 14),
                        const SizedBox(width: 4),
                        const Text('Admin ↔ Moto'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildChat(
                    corridaId: widget.rideId,
                    motoristaId: ride?.motoristaId ?? 'moto',
                    motoristaName: ride?.motoristaName ?? 'Motorista',
                    empresaId: ride?.empresaId ?? widget.currentUserId,
                    empresaName: ride?.empresaName ?? widget.currentUserName,
                  ),
                  _buildChat(
                    corridaId: 'admin_${widget.rideId}',
                    motoristaId: ride?.motoristaId ?? 'moto',
                    motoristaName: ride?.motoristaName ?? 'Motorista',
                    empresaId: 'admin',
                    empresaName: 'Liocer Admin',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(LiveRideModel ride) {
    final phases = [
      _Phase(icon: Icons.search_rounded, label: 'Buscando', step: 0),
      _Phase(icon: Icons.motorcycle_rounded, label: 'A caminho', step: 1),
      _Phase(icon: Icons.store_rounded, label: 'Na loja', step: 2),
      _Phase(icon: Icons.delivery_dining_rounded, label: 'Entregando', step: 3),
      _Phase(icon: Icons.check_circle_rounded, label: 'Entregue!', step: 4),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: phases.map((p) {
          final done = ride.status > p.step;
          final active = ride.status == p.step;
          final color = done || active ? _red : Colors.grey.shade300;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: done ? _red : active ? _red.withOpacity(0.12) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Icon(p.icon,
                      size: 15,
                      color: done ? Colors.white : active ? _red : Colors.grey),
                ),
                const SizedBox(height: 3),
                Text(
                  p.label,
                  style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? _red : done ? _textPrimary : Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _chatTab1Label(LiveRideModel? ride) {
    if (ride == null) return 'Chat';
    final name = ride.empresaName.split(' ').first;
    return '$name ↔ Moto';
  }

  Widget _buildChat({
    required String corridaId,
    required String motoristaId,
    required String motoristaName,
    required String empresaId,
    required String empresaName,
  }) {
    return ChatScreen(
      corridaId: corridaId,
      motoristaId: motoristaId,
      motoristaName: motoristaName,
      empresaId: empresaId,
      empresaName: empresaName,
      currentUserId: widget.currentUserId,
      currentUserName: widget.currentUserName,
      currentUserType: widget.currentUserType,
    );
  }
}

class _Phase {
  final IconData icon;
  final String label;
  final int step;
  const _Phase({required this.icon, required this.label, required this.step});
}
