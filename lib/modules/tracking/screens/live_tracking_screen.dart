import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/location_update_model.dart';
import '../services/tracking_service.dart';
import 'package:flutter/foundation.dart';

/// Tela de rastreamento em tempo real integrada com Firestore
class LiveTrackingScreen extends StatefulWidget {
  final String corridaId;
  final String trackedUserId; // ID do usuário sendo rastreado (motorista)
  final double initialLatitude;
  final double initialLongitude;

  const LiveTrackingScreen({
    Key? key,
    required this.corridaId,
    required this.trackedUserId,
    required this.initialLatitude,
    required this.initialLongitude,
  }) : super(key: key);

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  LocationUpdateModel? _currentLocation;
  final Set<Marker> _markers = {};
  StreamSubscription? _firestoreSubscription;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  void _initializeTracking() async {
    // Primeiro, tenta buscar última posição do Firestore
    final lastLocation = await TrackingService.getLastLocationFromFirestore(widget.corridaId);
    if (lastLocation != null && mounted) {
      setState(() {
        _currentLocation = lastLocation;
        _updateMarker();
      });
    } else if (widget.initialLatitude != 0.0 && widget.initialLongitude != 0.0) {
      // Usa posição inicial se não houver no Firestore
      setState(() {
        _currentLocation = LocationUpdateModel(
          id: 'initial',
          corridaId: widget.corridaId,
          userId: widget.trackedUserId,
          latitude: widget.initialLatitude,
          longitude: widget.initialLongitude,
          timestamp: DateTime.now(),
        );
        _updateMarker();
      });
    }

    // Adiciona listener local (para atualizações do próprio dispositivo)
    TrackingService.addLocationListener(_onLocationUpdate);

    // Escuta atualizações em tempo real do Firestore
    _firestoreSubscription = TrackingService.listenToLocationUpdates(
      widget.corridaId,
      _onLocationUpdate,
    );
  }

  void _onLocationUpdate(LocationUpdateModel update) {
    if (update.userId == widget.trackedUserId && mounted) {
      setState(() {
        _currentLocation = update;
        _updateMarker();
        _moveCamera();
      });
    }
  }

  void _updateMarker() {
    if (_currentLocation == null) return;

    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('tracked_user'),
        position: LatLng(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        rotation: _currentLocation!.heading ?? 0.0,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: 'Motorista',
          snippet: _currentLocation!.speed != null
              ? 'Velocidade: ${(_currentLocation!.speed! * 3.6).toStringAsFixed(1)} km/h'
              : 'Em movimento',
        ),
      ),
    );
  }

  void _moveCamera() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    TrackingService.removeLocationListener(_onLocationUpdate);
    _firestoreSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF7F5FA);
    const Color cardBackground = Colors.white;
    const Color primaryRed = Color(0xFFE53935);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Rastreamento em Tempo Real',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        backgroundColor: cardBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      body: Stack(
        children: [
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
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentLocation != null) {
                _moveCamera();
              }
            },
          ),
          if (_currentLocation != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rastreamento ativo',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (_currentLocation!.speed != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            size: 20,
                            color: primaryRed,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(_currentLocation!.speed! * 3.6).toStringAsFixed(1)} km/h',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Última atualização: ${_formatTime(_currentLocation!.timestamp)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentLocation == null)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min atrás';
    } else {
      return '${difference.inHours} h atrás';
    }
  }
}





