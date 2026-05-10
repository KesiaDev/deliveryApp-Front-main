import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/modules/payments/services/payment_service.dart';
import 'package:delivery_front/modules/payments/screens/pix_qr_code_screen.dart';
import 'package:delivery_front/modules/payments/screens/payment_review_screen.dart';
import 'package:delivery_front/modules/payments/models/payment_model.dart';
import '../services/live_ride_service.dart';
import 'waiting_driver_screen.dart';

/// Tela de solicitação de entrega (empresa) — estilo Uber/iFood
class DeliveryRequestScreen extends StatefulWidget {
  final Usuario user;

  const DeliveryRequestScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<DeliveryRequestScreen> createState() => _DeliveryRequestScreenState();
}

class _DeliveryRequestScreenState extends State<DeliveryRequestScreen> {
  static const Color _red = Color(0xFFE53935);
  static const Color _bg = Color(0xFFF7F5FA);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF757575);

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};

  // Pickup (empresa) — padrão neutro, substituído por _loadEmpresaInfo()
  double _pickupLat = -15.7801; // Brasília — centro do Brasil como fallback neutro
  double _pickupLng = -47.9292;
  String _pickupAddress = '';
  String _pickupName = '';

  // Delivery
  double? _deliveryLat;
  double? _deliveryLng;
  String _deliveryAddress = '';

  // Form
  final _deliveryCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _paymentType = 'pix';
  bool _isRequesting = false;
  bool _searchingAddr = false;
  List<_AddressSuggestion> _suggestions = [];
  Timer? _debounce;

  // Estimativa
  double _distanceKm = 0;
  double _price = 0;

  @override
  void initState() {
    super.initState();
    _loadEmpresaInfo();
  }

  void _loadEmpresaInfo() {
    final resp = widget.user.usuarioResp;
    if (resp == null) return;

    final empresa = resp.empresas?.isNotEmpty == true ? resp.empresas!.first : null;
    if (empresa != null) {
      final lat = resp.desLatitude;
      final lng = resp.desLongitude;
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        _pickupLat = lat;
        _pickupLng = lng;
      }
      final end = empresa.enderecos?.isNotEmpty == true ? empresa.enderecos!.first : null;
      if (end != null) {
        _pickupAddress =
            '${end.desRua ?? ''}, ${end.desNumero ?? ''} - ${end.desCidade ?? ''}';
      }
      _pickupName =
          empresa.desNomeFantasia ?? empresa.desRazaoSocial ?? widget.user.desNome ?? 'Loja';
    } else {
      _pickupName = widget.user.desNome ?? 'Empresa';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshMap());
  }

  void _refreshMap() {
    _markers.clear();
    _markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: LatLng(_pickupLat, _pickupLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(title: _pickupName, snippet: 'Local de retirada'),
    ));
    if (_deliveryLat != null) {
      _markers.add(Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(_deliveryLat!, _deliveryLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Entregar aqui', snippet: _deliveryAddress),
      ));
    }
    if (mounted) setState(() {});
    _fitCamera();
  }

  void _fitCamera() {
    if (_mapController == null) return;
    if (_deliveryLat == null) {
      _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(_pickupLat, _pickupLng), 15));
      return;
    }
    final minLat = min(_pickupLat, _deliveryLat!);
    final maxLat = max(_pickupLat, _deliveryLat!);
    final minLng = min(_pickupLng, _deliveryLng!);
    final maxLng = max(_pickupLng, _deliveryLng!);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      72,
    ));
  }

  Future<void> _drawPolyline() async {
    if (_deliveryLat == null) return;
    try {
      final pp = PolylinePoints(apiKey: ApiBaseHelper.GEO_KEY);
      final result = await pp.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(_pickupLat, _pickupLng),
          destination: PointLatLng(_deliveryLat!, _deliveryLng!),
          mode: TravelMode.driving,
        ),
      );
      final pts = result.points.isNotEmpty
          ? result.points.map((p) => LatLng(p.latitude, p.longitude)).toList()
          : [LatLng(_pickupLat, _pickupLng), LatLng(_deliveryLat!, _deliveryLng!)];

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
        points: [LatLng(_pickupLat, _pickupLng), LatLng(_deliveryLat!, _deliveryLng!)],
        color: _red.withOpacity(0.7),
        width: 3,
        patterns: [PatternItem.dash(12), PatternItem.gap(6)],
      );
    }

    // Estimativa de distância + preço
    final dLat = (_deliveryLat! - _pickupLat).abs();
    final dLng = (_deliveryLng! - _pickupLng).abs();
    _distanceKm = ((dLat * 111) + (dLng * 85)) * 1.3;
    _price = 5.0 + (_distanceKm * 2.5);

    if (mounted) setState(() {});
    _fitCamera();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _searchingAddr = true);
      try {
        final locs = await geo.locationFromAddress('$value, Brasil');
        if (locs.isEmpty || !mounted) return;
        final suggestions = <_AddressSuggestion>[];
        for (final loc in locs.take(4)) {
          final marks = await geo.placemarkFromCoordinates(
              loc.latitude, loc.longitude);
          for (final m in marks.take(1)) {
            final parts = [
              m.street,
              m.subLocality,
              m.locality,
              m.administrativeArea,
            ].where((e) => e != null && e.isNotEmpty).toList();
            final addr = parts.join(', ');
            if (addr.isNotEmpty) {
              suggestions.add(_AddressSuggestion(
                  label: addr, lat: loc.latitude, lng: loc.longitude));
            }
          }
        }
        if (suggestions.isEmpty) {
          suggestions.add(_AddressSuggestion(
            label: value,
            lat: locs.first.latitude,
            lng: locs.first.longitude,
          ));
        }
        if (mounted) setState(() => _suggestions = suggestions);
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      } finally {
        if (mounted) setState(() => _searchingAddr = false);
      }
    });
  }

  void _selectSuggestion(_AddressSuggestion s) {
    _deliveryLat = s.lat;
    _deliveryLng = s.lng;
    _deliveryAddress = s.label;
    _deliveryCtrl.text = s.label;
    setState(() => _suggestions = []);
    _refreshMap();
    _drawPolyline();
  }

  Future<void> _requestDelivery() async {
    if (_deliveryLat == null) {
      _snack('Informe o endereço de entrega');
      return;
    }
    if (_clientNameCtrl.text.trim().isEmpty) {
      _snack('Informe o nome do destinatário');
      return;
    }
    if (_distanceKm <= 0) {
      _snack('Aguarde o cálculo da distância');
      return;
    }

    // Pagamento obrigatório antes de liberar pro motorista (exceto dinheiro)
    if (_paymentType != 'dinheiro') {
      final paid = await _processPayment();
      if (!paid) return;
    }

    setState(() => _isRequesting = true);
    try {
      final rideId = await LiveRideService.createRide(
        empresaId: widget.user.codUsuario?.toString() ?? 'emp_demo',
        empresaName: _pickupName,
        pickupName: _pickupName,
        pickupAddress: _pickupAddress,
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        deliveryAddress: _deliveryCtrl.text.trim(),
        deliveryClientName: _clientNameCtrl.text.trim(),
        deliveryLat: _deliveryLat!,
        deliveryLng: _deliveryLng!,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        paymentType: _paymentType,
        price: _price,
        distanceKm: _distanceKm,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WaitingDriverScreen(
            rideId: rideId,
            pickupLat: _pickupLat,
            pickupLng: _pickupLng,
            pickupAddress: _pickupAddress,
            pickupName: _pickupName,
            deliveryAddress: _deliveryCtrl.text.trim(),
            deliveryClientName: _clientNameCtrl.text.trim(),
            deliveryLat: _deliveryLat!,
            deliveryLng: _deliveryLng!,
            empresaId: widget.user.codUsuario?.toString() ?? 'emp_demo',
            empresaName: _pickupName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) _snack('Erro ao solicitar: $e');
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  /// Processa pagamento antes de criar a corrida.
  /// Retorna true se pago/confirmado, false se cancelado ou com erro.
  Future<bool> _processPayment() async {
    final tempRef = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final desc = 'Entrega para ${_clientNameCtrl.text.trim()}';

    if (_paymentType == 'pix') {
      setState(() => _isRequesting = true);
      try {
        final pixData = await PaymentService.generatePixQrCode(
          amount: _price,
          description: desc,
          corridaId: tempRef,
        );
        if (!mounted) return false;
        setState(() => _isRequesting = false);

        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PixQrCodeScreen(
              corridaId: tempRef,
              amount: _price,
              pixCopyPaste: pixData.pixCopyPaste,
              qrCodeImage: pixData.qrCodeImage,
            ),
          ),
        );
        return paid == true;
      } catch (e) {
        if (mounted) {
          setState(() => _isRequesting = false);
          _snack('Erro ao gerar PIX: $e');
        }
        return false;
      }
    }

    if (_paymentType == 'cartao') {
      final paid = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentReviewScreen(
            corridaId: tempRef,
            amount: _price,
            method: PaymentMethod.creditCard,
            description: desc,
          ),
        ),
      );
      return paid == true;
    }

    return true; // dinheiro — sem gate de pagamento
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _debounce?.cancel();
    _deliveryCtrl.dispose();
    _clientNameCtrl.dispose();
    _notesCtrl.dispose();
    _mapController?.dispose();
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
        title: Text(
          'Solicitar Entrega',
          style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w600, color: _textPrimary),
        ),
      ),
      body: Column(
        children: [
          // ── Mapa ─────────────────────────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.32,
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: LatLng(_pickupLat, _pickupLng), zoom: 14),
              markers: _markers,
              polylines: _polylines.values.toSet(),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              onMapCreated: (c) {
                _mapController = c;
                _fitCamera();
              },
            ),
          ),

          // ── Formulário ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // De: (empresa)
                  _LocationRow(
                    icon: Icons.store_mall_directory_rounded,
                    iconColor: Colors.blue,
                    label: 'Retirada em',
                    value: _pickupName,
                    subtitle: _pickupAddress,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 19, top: 2, bottom: 2),
                    child: Column(
                      children: List.generate(
                          3,
                          (_) => Container(
                              width: 2,
                              height: 4,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              color: Colors.grey.shade300)),
                    ),
                  ),

                  // Para: (delivery address search)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.location_on_rounded,
                              color: Colors.green.shade600, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Entregar em',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: _textSecondary)),
                              TextField(
                                controller: _deliveryCtrl,
                                style: GoogleFonts.poppins(
                                    fontSize: 14, color: _textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Rua, número, bairro...',
                                  hintStyle: GoogleFonts.poppins(
                                      fontSize: 13, color: Colors.grey.shade400),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  suffix: _searchingAddr
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : null,
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sugestões
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Column(
                        children: _suggestions
                            .map((s) => ListTile(
                                  dense: true,
                                  leading: Icon(Icons.place_outlined,
                                      size: 18, color: _red),
                                  title: Text(s.label,
                                      style: GoogleFonts.poppins(fontSize: 13)),
                                  onTap: () => _selectSuggestion(s),
                                ))
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Nome do destinatário
                  _TextField(
                    label: 'Destinatário',
                    hint: 'Ex: João Silva',
                    icon: Icons.person_outline_rounded,
                    controller: _clientNameCtrl,
                  ),
                  const SizedBox(height: 10),

                  // Observações
                  _TextField(
                    label: 'Observações (opcional)',
                    hint: 'Ex: Ap. 301, ligar antes de entregar...',
                    icon: Icons.notes_rounded,
                    controller: _notesCtrl,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),

                  // Pagamento
                  Text('Forma de pagamento',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _PayChip(
                          label: 'PIX',
                          icon: Icons.pix,
                          selected: _paymentType == 'pix',
                          onTap: () => setState(() => _paymentType = 'pix')),
                      const SizedBox(width: 8),
                      _PayChip(
                          label: 'Cartão',
                          icon: Icons.credit_card_rounded,
                          selected: _paymentType == 'cartao',
                          onTap: () => setState(() => _paymentType = 'cartao')),
                      const SizedBox(width: 8),
                      _PayChip(
                          label: 'Dinheiro',
                          icon: Icons.attach_money_rounded,
                          selected: _paymentType == 'dinheiro',
                          onTap: () => setState(() => _paymentType = 'dinheiro')),
                    ],
                  ),

                  // Estimativa de preço
                  if (_distanceKm > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Distância estimada',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11, color: _textSecondary)),
                                Text('${_distanceKm.toStringAsFixed(1)} km',
                                    style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimary)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Valor aprox.',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: _textSecondary)),
                              Text(
                                'R\$ ${_price.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: _red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Botão solicitar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : _requestDelivery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isRequesting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _paymentType == 'pix'
                                      ? Icons.pix
                                      : _paymentType == 'cartao'
                                          ? Icons.credit_card_rounded
                                          : Icons.motorcycle_rounded,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _paymentType == 'dinheiro'
                                      ? 'Solicitar Motoboy'
                                      : 'Pagar e Solicitar',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Auxiliares ────────────────────────────────────────────────────────────────

class _AddressSuggestion {
  final String label;
  final double lat;
  final double lng;
  const _AddressSuggestion(
      {required this.label, required this.lat, required this.lng});
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;

  const _LocationRow(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFF757575))),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A))),
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

class _TextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final int maxLines;

  const _TextField(
      {required this.label,
      required this.hint,
      required this.icon,
      required this.controller,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(icon, size: 18, color: const Color(0xFF757575)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: const Color(0xFF757575))),
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: const Color(0xFF1A1A1A)),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade400),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PayChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  static const _red = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _red : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _red : const Color(0xFFDDDDDD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : const Color(0xFF757575)),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : const Color(0xFF757575))),
          ],
        ),
      ),
    );
  }
}
