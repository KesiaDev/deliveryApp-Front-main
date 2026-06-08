import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:delivery_front/modules/tracking/services/tracking_service.dart';
import 'package:delivery_front/modules/tracking/models/location_update_model.dart';
import 'package:delivery_front/modules/chat/screens/chat_screen.dart';

/// Tela unificada: mapa ao vivo + chat cliente↔motorista + chat admin↔motorista
class CorridaMonitorScreen extends StatefulWidget {
  final String corridaId;
  final String motoristaId;
  final String motoristaName;
  final String clienteId;
  final String clienteName;
  final String adminId;
  final String adminName;
  final double initialLat;
  final double initialLng;

  const CorridaMonitorScreen({
    Key? key,
    required this.corridaId,
    required this.motoristaId,
    required this.motoristaName,
    required this.clienteId,
    required this.clienteName,
    required this.adminId,
    required this.adminName,
    this.initialLat = -23.5505,
    this.initialLng = -46.6333,
  }) : super(key: key);

  @override
  State<CorridaMonitorScreen> createState() => _CorridaMonitorScreenState();
}

class _CorridaMonitorScreenState extends State<CorridaMonitorScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  LocationUpdateModel? _currentLocation;
  final Set<Marker> _markers = {};
  StreamSubscription? _trackingSubscription;
  late TabController _tabController;

  static const Color _bg = Color(0xFFF7F5FA);
  static const Color _red = Color(0xFFE53935);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initTracking();
  }

  Future<void> _initTracking() async {
    final last = await TrackingService.getLastLocationFromFirestore(widget.corridaId);
    if (last != null && mounted) {
      setState(() {
        _currentLocation = last;
        _updateMarker();
      });
    } else {
      setState(() {
        _currentLocation = LocationUpdateModel(
          id: 'initial',
          corridaId: widget.corridaId,
          userId: widget.motoristaId,
          latitude: widget.initialLat,
          longitude: widget.initialLng,
          timestamp: DateTime.now(),
        );
        _updateMarker();
      });
    }

    _trackingSubscription = TrackingService.listenToLocationUpdates(
      widget.corridaId,
      _onLocationUpdate,
    );
  }

  void _onLocationUpdate(LocationUpdateModel update) {
    if (!mounted) return;
    setState(() {
      _currentLocation = update;
      _updateMarker();
      _animateCamera();
    });
  }

  void _updateMarker() {
    if (_currentLocation == null) return;
    _markers.clear();
    _markers.add(Marker(
      markerId: const MarkerId('motorista'),
      position: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      rotation: _currentLocation!.heading ?? 0.0,
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(
        title: '🛵 ${widget.motoristaName}',
        snippet: _currentLocation!.speed != null
            ? '${(_currentLocation!.speed! * 3.6).toStringAsFixed(0)} km/h'
            : 'Em movimento',
      ),
    ));
  }

  void _animateCamera() {
    if (_mapController == null || _currentLocation == null) return;
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
      ),
    );
  }

  String get _speedLabel {
    if (_currentLocation?.speed == null) return '—';
    return '${(_currentLocation!.speed! * 3.6).toStringAsFixed(0)} km/h';
  }

  String get _corridaLabel {
    final id = widget.corridaId;
    return '#${id.length > 10 ? id.substring(0, 10) : id}';
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    TrackingService.removeLocationListener(_onLocationUpdate);
    _mapController = null;
    _tabController.dispose();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Corrida ao Vivo',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _corridaLabel,
                  style: GoogleFonts.poppins(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.speed_rounded, size: 14, color: _red),
                const SizedBox(width: 4),
                Text(
                  _speedLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Mapa (40% da tela) ────────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.38,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentLocation?.latitude ?? widget.initialLat,
                      _currentLocation?.longitude ?? widget.initialLng,
                    ),
                    zoom: 15.5,
                  ),
                  markers: _markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_currentLocation != null) _animateCamera();
                  },
                ),

                // Chip "AO VIVO" no canto superior
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'AO VIVO',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Card de info do motorista na base do mapa
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _red,
                          child: Text(
                            widget.motoristaName.isNotEmpty
                                ? widget.motoristaName[0].toUpperCase()
                                : 'M',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.motoristaName,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                              Text(
                                'Motorista • $_speedLabel',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'em rota',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── TabBar ─────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: _red,
              unselectedLabelColor: _textSecondary,
              indicatorColor: _red,
              indicatorWeight: 2.5,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_rounded, size: 15),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${widget.clienteName.split(' ').first} ↔ Moto',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded, size: 15),
                      const SizedBox(width: 5),
                      const Text('Admin ↔ Moto'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Chats (60% restante) ────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: observar conversa cliente ↔ motorista (admin só lê + pode enviar)
                ChatScreen(
                  corridaId: widget.corridaId,
                  motoristaId: widget.motoristaId,
                  motoristaName: widget.motoristaName,
                  empresaId: widget.clienteId,
                  empresaName: widget.clienteName,
                  currentUserId: widget.adminId,
                  currentUserName: widget.adminName,
                  currentUserType: 'admin',
                ),

                // Tab 2: canal privado Admin ↔ Motorista (sala separada no Firestore)
                ChatScreen(
                  corridaId: 'admin_${widget.corridaId}',
                  motoristaId: widget.motoristaId,
                  motoristaName: widget.motoristaName,
                  empresaId: widget.adminId,
                  empresaName: widget.adminName,
                  currentUserId: widget.adminId,
                  currentUserName: widget.adminName,
                  currentUserType: 'admin',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
