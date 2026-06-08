import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/live_ride_model.dart';
import '../services/live_ride_service.dart';
import 'live_ride_map_screen.dart';

/// Tela da EMPRESA após solicitar entrega — aguarda motoboy aceitar (estilo Uber)
class WaitingDriverScreen extends StatefulWidget {
  final String rideId;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final String pickupName;
  final double deliveryLat;
  final double deliveryLng;
  final String deliveryAddress;
  final String deliveryClientName;
  final String empresaId;
  final String empresaName;

  const WaitingDriverScreen({
    Key? key,
    required this.rideId,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.pickupName,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.deliveryAddress,
    required this.deliveryClientName,
    required this.empresaId,
    required this.empresaName,
  }) : super(key: key);

  @override
  State<WaitingDriverScreen> createState() => _WaitingDriverScreenState();
}

class _WaitingDriverScreenState extends State<WaitingDriverScreen>
    with SingleTickerProviderStateMixin {
  static const _red = Color(0xFFE53935);
  static const _bg = Color(0xFFF7F5FA);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF757575);

  LiveRideModel? _ride;
  StreamSubscription? _rideSub;
  GoogleMapController? _mapController;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final Set<Marker> _markers = {};
  bool _navigatedToLive = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _setupMarkers();
    _listenToRide();
  }

  void _setupMarkers() {
    _markers
      ..add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.pickupLat, widget.pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: widget.pickupName, snippet: 'Retirada'),
      ))
      ..add(Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(widget.deliveryLat, widget.deliveryLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow:
            InfoWindow(title: widget.deliveryClientName, snippet: 'Entrega'),
      ));
  }

  void _listenToRide() {
    _rideSub =
        LiveRideService.listenToRide(widget.rideId).listen((ride) {
      if (!mounted) return;
      setState(() => _ride = ride);
      // Quando motorista aceitar (status>=1) → vai para tela ao vivo
      if (ride != null && ride.status >= 1 && !_navigatedToLive) {
        _navigatedToLive = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LiveRideMapScreen(
                rideId: widget.rideId,
                currentUserId: widget.empresaId,
                currentUserName: widget.empresaName,
                currentUserType: 'empresa',
              ),
            ),
          );
        });
      }
    });
  }

  Future<void> _cancelRide() async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancelar entrega?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Deseja cancelar a solicitação?',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Não', style: GoogleFonts.poppins(color: _textSecondary))),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Cancelar entrega',
                  style: GoogleFonts.poppins(color: _red, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm == true) {
      await LiveRideService.updateStatus(widget.rideId, 5);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _rideSub?.cancel();
    _pulseCtrl.dispose();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelRide();
      },
      child: Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Mapa fullscreen ───────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                (widget.pickupLat + widget.deliveryLat) / 2,
                (widget.pickupLng + widget.deliveryLng) / 2,
              ),
              zoom: 13,
            ),
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (c) {
              _mapController = c;
              Future.delayed(const Duration(milliseconds: 400), () {
                if (!mounted) return;
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(
                      southwest: LatLng(
                        widget.pickupLat < widget.deliveryLat
                            ? widget.pickupLat
                            : widget.deliveryLat,
                        widget.pickupLng < widget.deliveryLng
                            ? widget.pickupLng
                            : widget.deliveryLng,
                      ),
                      northeast: LatLng(
                        widget.pickupLat > widget.deliveryLat
                            ? widget.pickupLat
                            : widget.deliveryLat,
                        widget.pickupLng > widget.deliveryLng
                            ? widget.pickupLng
                            : widget.deliveryLng,
                      ),
                    ),
                    72,
                  ),
                );
              });
            },
          ),

          // ── Botão voltar ──────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            child: GestureDetector(
              onTap: _cancelRide,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child:
                    const Icon(Icons.arrow_back_rounded, color: _textPrimary, size: 22),
              ),
            ),
          ),

          // ── Bottom sheet: aguardando ──────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),

                  // Animação de busca
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 72 * _pulseAnim.value,
                          height: 72 * _pulseAnim.value,
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.12 * (2 - _pulseAnim.value)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: _red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.motorcycle_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Buscando motoboy...',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Procurando motoboys disponíveis\npróximos à sua loja',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Rota resumida
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _RouteRow(
                          icon: Icons.store_mall_directory_rounded,
                          color: Colors.blue,
                          label: 'De',
                          value: widget.pickupName,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
                          child: Row(children: [
                            Container(width: 2, height: 16, color: Colors.grey.shade300),
                          ]),
                        ),
                        _RouteRow(
                          icon: Icons.location_on_rounded,
                          color: Colors.green.shade600,
                          label: 'Para',
                          value: widget.deliveryClientName,
                          subtitle: widget.deliveryAddress,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cancelar
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _cancelRide,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: const BorderSide(color: _red, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Cancelar solicitação',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? subtitle;

  const _RouteRow(
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
        Icon(icon, size: 18, color: color),
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
