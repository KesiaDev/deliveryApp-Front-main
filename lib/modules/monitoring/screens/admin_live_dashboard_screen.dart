import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/live_ride_model.dart';
import '../services/live_ride_service.dart';
import 'live_ride_map_screen.dart';

/// Dashboard de admin: mapa com TODOS os motoboys ativos + lista de corridas
class AdminLiveDashboardScreen extends StatefulWidget {
  final String adminId;
  final String adminName;

  const AdminLiveDashboardScreen({
    Key? key,
    required this.adminId,
    required this.adminName,
  }) : super(key: key);

  @override
  State<AdminLiveDashboardScreen> createState() =>
      _AdminLiveDashboardScreenState();
}

class _AdminLiveDashboardScreenState extends State<AdminLiveDashboardScreen> {
  static const _red = Color(0xFFE53935);
  static const _bg = Color(0xFFF7F5FA);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF757575);

  List<LiveRideModel> _activeRides = [];
  StreamSubscription? _sub;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Filtro de status
  int? _filterStatus; // null = todos

  @override
  void initState() {
    super.initState();
    _listenActiveRides();
  }

  void _listenActiveRides() {
    _sub = LiveRideService.listenToActiveRides().listen((rides) {
      if (!mounted) return;
      setState(() => _activeRides = rides);
      _updateMarkers(rides);
    });
  }

  void _updateMarkers(List<LiveRideModel> rides) {
    _markers.clear();
    for (final ride in rides) {
      // Marcador da loja (pickup)
      _markers.add(Marker(
        markerId: MarkerId('pickup_${ride.rideId}'),
        position: LatLng(ride.pickupLat, ride.pickupLng),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
            title: ride.pickupName,
            snippet: ride.statusLabel),
      ));

      // Marcador do motorista (quando disponível)
      if (ride.motoristaLat != null) {
        _markers.add(Marker(
          markerId: MarkerId('moto_${ride.rideId}'),
          position: LatLng(ride.motoristaLat!, ride.motoristaLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '🛵 ${ride.motoristaName ?? 'Motorista'}',
            snippet: '${ride.statusLabel} → ${ride.deliveryClientName}',
          ),
          zIndex: 2,
          onTap: () => _openRide(ride),
        ));
      }
    }
    if (mounted) setState(() {});
  }

  void _openRide(LiveRideModel ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveRideMapScreen(
          rideId: ride.rideId,
          currentUserId: widget.adminId,
          currentUserName: widget.adminName,
          currentUserType: 'admin',
        ),
      ),
    );
  }

  List<LiveRideModel> get _filteredRides => _filterStatus == null
      ? _activeRides
      : _activeRides.where((r) => r.status == _filterStatus).toList();

  Color _statusColor(int s) {
    switch (s) {
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

  @override
  void dispose() {
    _sub?.cancel();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRides;
    final buscando = _activeRides.where((r) => r.status == 0).length;
    final emRota = _activeRides.where((r) => r.status >= 1 && r.status <= 3).length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: Text(
          'Corridas ao Vivo',
          style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w600, color: _textPrimary),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('${_activeRides.length} ativa${_activeRides.length != 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── STATS BAR ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                _StatChip(
                    label: 'Buscando',
                    count: buscando,
                    color: Colors.orange,
                    selected: _filterStatus == 0,
                    onTap: () => setState(
                        () => _filterStatus = _filterStatus == 0 ? null : 0)),
                const SizedBox(width: 8),
                _StatChip(
                    label: 'Em rota',
                    count: emRota,
                    color: _red,
                    selected: _filterStatus == 3,
                    onTap: () => setState(
                        () => _filterStatus = _filterStatus == 3 ? null : 3)),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      setState(() => _filterStatus = null),
                  child: Text('Todas',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _filterStatus == null ? _red : _textSecondary,
                          fontWeight: _filterStatus == null
                              ? FontWeight.w700
                              : FontWeight.w400)),
                ),
              ],
            ),
          ),

          // ── MAPA ─────────────────────────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.34,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-23.5505, -46.6333),
                    zoom: 12,
                  ),
                  markers: _markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  onMapCreated: (c) => _mapController = c,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text('AO VIVO',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── LISTA de corridas ─────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.motorcycle_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text('Nenhuma corrida ativa',
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: _textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _AdminRideCard(
                      ride: filtered[i],
                      statusColor: _statusColor(filtered[i].status),
                      onTap: () => _openRide(filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatChip(
      {required this.label,
      required this.count,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : const Color(0xFFF7F5FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('$count $label',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : const Color(0xFF757575))),
          ],
        ),
      ),
    );
  }
}

class _AdminRideCard extends StatelessWidget {
  final LiveRideModel ride;
  final Color statusColor;
  final VoidCallback onTap;

  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF757575);

  const _AdminRideCard(
      {required this.ride,
      required this.statusColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.motorcycle_rounded,
                  color: statusColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${ride.pickupName} → ${ride.deliveryClientName}',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(ride.statusLabel,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ride.motoristaName != null
                        ? '🛵 ${ride.motoristaName}'
                        : '⏳ Aguardando motoboy...',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: _textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${ride.distanceKm.toStringAsFixed(1)}km • R\$ ${ride.price.toStringAsFixed(2)} • ${ride.paymentType.toUpperCase()}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
