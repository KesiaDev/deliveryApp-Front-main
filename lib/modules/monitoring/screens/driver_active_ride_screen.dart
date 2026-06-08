import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../models/live_ride_model.dart';
import '../services/live_ride_service.dart';
import 'live_ride_map_screen.dart';

/// Extende o LiveRideMapScreen para o MOTORISTA com controles de status
/// + GPS tracking automático durante a corrida
class DriverActiveRideScreen extends StatefulWidget {
  final String rideId;
  final String motoristaId;
  final String motoristaName;

  const DriverActiveRideScreen({
    Key? key,
    required this.rideId,
    required this.motoristaId,
    required this.motoristaName,
  }) : super(key: key);

  @override
  State<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  static const _red = Color(0xFFE53935);
  static const _textSecondary = Color(0xFF757575);

  LiveRideModel? _ride;
  StreamSubscription? _rideSub;
  StreamSubscription<Position>? _gpsSub;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _listenRide();
    _startGPS();
  }

  void _listenRide() {
    _rideSub = LiveRideService.listenToRide(widget.rideId).listen((r) {
      if (mounted) setState(() => _ride = r);
    });
  }

  Future<void> _startGPS() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    if (!mounted) return; // Widget pode ter sido descartado durante a espera
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (!mounted) return;
      LiveRideService.updateDriverLocation(
          widget.rideId, pos.latitude, pos.longitude);
    });
  }

  Future<void> _advanceStatus() async {
    final ride = _ride;
    if (ride == null || _updating) return;
    setState(() => _updating = true);
    try {
      final next = ride.status + 1;
      await LiveRideService.updateStatus(widget.rideId, next);
      if (next == 4 && mounted) {
        // Entregue! Para GPS e retorna
        _gpsSub?.cancel();
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Entrega concluída!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            content: Text(
                'Parabéns! A entrega foi concluída com sucesso.',
                style: GoogleFonts.poppins(fontSize: 14)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _red),
                onPressed: () => Navigator.of(context)
                  ..pop()
                  ..pop(),
                child: Text('OK',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  String _nextActionLabel(int status) {
    switch (status) {
      case 1:
        return 'Cheguei na loja';
      case 2:
        return 'Retirei o pacote';
      case 3:
        return 'Entrega realizada!';
      default:
        return '';
    }
  }

  IconData _nextActionIcon(int status) {
    switch (status) {
      case 1:
        return Icons.store_rounded;
      case 2:
        return Icons.delivery_dining_rounded;
      case 3:
        return Icons.check_circle_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  @override
  void dispose() {
    _rideSub?.cancel();
    _gpsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    final showAction =
        ride != null && ride.status >= 1 && ride.status <= 3;

    return Stack(
      children: [
        // Mapa ao vivo por baixo
        LiveRideMapScreen(
          rideId: widget.rideId,
          currentUserId: widget.motoristaId,
          currentUserName: widget.motoristaName,
          currentUserType: 'motorista',
        ),

        // Botão de avançar status (flutuante)
        if (showAction)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -4))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  if (ride != null) ...[
                    Text(
                      ride.status == 1
                          ? 'A caminho de: ${ride.pickupName}'
                          : ride.status == 2
                              ? 'Retire em: ${ride.pickupAddress}'
                              : 'Entregar para: ${ride.deliveryClientName}',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _textSecondary),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _updating ? null : _advanceStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ride.status == 3
                              ? Colors.green
                              : _red,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _updating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Icon(_nextActionIcon(ride.status), size: 22),
                        label: Text(
                          _updating
                              ? 'Atualizando...'
                              : _nextActionLabel(ride.status),
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
