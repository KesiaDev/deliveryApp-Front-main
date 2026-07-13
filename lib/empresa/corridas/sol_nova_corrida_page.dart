import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/home/widgets/task_column.dart';
import 'package:delivery_front/login/login_controller.dart';
import 'package:delivery_front/modules/monitoring/services/live_ride_service.dart';
import 'package:delivery_front/modules/cod/models/cod_model.dart';
import 'package:delivery_front/modules/cod/services/cod_service.dart';
import 'package:delivery_front/modules/payments/models/empresa_payment_config.dart';
import 'package:delivery_front/modules/payments/screens/card_payment_screen.dart';
import 'package:delivery_front/modules/payments/screens/pix_qr_code_screen.dart';
import 'package:delivery_front/modules/payments/services/empresa_payment_service.dart';
import 'package:delivery_front/modules/payments/services/payment_service.dart';
import 'package:delivery_front/shared/components/loading_dialog.dart';
import 'package:delivery_front/shared/models/TipoCorrida.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' show cos, sqrt, asin;
import 'dart:ui' as ui;

class _NovaCorridaPageState extends StatefulWidget {
  _NovaCorridaPageState();

  @override
  __NovaCorridaPageStateState createState() =>
      new __NovaCorridaPageStateState();
}

var rua;
var indTipoPgto = TipoCorrida(indTipo: 1, desTipo: "Cartão", isSelected: true);
var _desTipoPgto;
var _listTiposCorridas = getTipoCorrida();
bool isEditado = false;
// Tipos filtrados por config da empresa (global para ser acessível de _AddressTile)
List<TipoCorrida> _tiposPermitidosGlobal = getTipoCorrida();
double _walletBalanceGlobal = 0.0;
late Widget dropOptions;
late BuildContext contextAux;

// Object for PolylinePoints
PolylinePoints polylinePoints = PolylinePoints(apiKey: ApiBaseHelper.GEO_KEY);

// List of coordinates to join
List<LatLng> polylineCoordinates = [];

// Map storing polylines created by connecting
// two points
Map<PolylineId, Polyline> polylines = {};

DropdownMenuItem<TipoCorrida> creatOption(TipoCorrida dropDownStringItem) {
  return DropdownMenuItem<TipoCorrida>(
    value: dropDownStringItem,
    child: Text(dropDownStringItem.desTipo),
  );
}

criaDropDownButton(final VoidCallback callback) {
  var _value;
  return Container(
    child: Column(
      children: <Widget>[
        Text("Forma de pagamento: '${indTipoPgto.desTipo}'"),
        new GestureDetector(
          onTap: () {
            DropdownButton<TipoCorrida>(
              items: _listTiposCorridas.map((dropDownStringItem) {
                return creatOption(dropDownStringItem);
              }).toList(),
              onChanged: (TipoCorrida? novoItemSelecionado) {
                _dropDownItemSelected(novoItemSelecionado!);
                _value = novoItemSelecionado;
                callback.call();
                isEditado = true;
              },
              value: indTipoPgto,
            );
          },
          child: new Text(indTipoPgto.desTipo),
        ),
        DropdownButton<TipoCorrida>(
          items: _listTiposCorridas.map((dropDownStringItem) {
            return creatOption(dropDownStringItem);
          }).toList(),
          onChanged: (TipoCorrida? novoItemSelecionado) {
            _dropDownItemSelected(novoItemSelecionado!);
            _value = novoItemSelecionado;
            callback.call();
            isEditado = true;
          },
          value: indTipoPgto,
        ),
      ],
    ),
  );
}

class __NovaCorridaPageStateState extends State<_NovaCorridaPageState> {
  __NovaCorridaPageStateState();

  final TextEditingController _controller = new TextEditingController();
  final UserService service = new UserService();

  List<Location> results = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool isLoading = false;
  Timer? _debounce;

  // Métodos filtrados por config da empresa
  List<TipoCorrida> _tiposPermitidos = getTipoCorrida();
  EmpresaPaymentConfig? _empresaConfig;
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEmpresaPaymentConfig();
  }

  Future<void> _loadEmpresaPaymentConfig() async {
    final emp = ApiBaseHelper.userSessao?.usuarioResp?.empresas?.firstOrNull;
    if (emp?.codEmpresa == null) return;
    try {
      final cfg = await EmpresaPaymentService.getConfig(emp!.codEmpresa!);
      final bal = await EmpresaPaymentService.getWalletBalance(emp.codEmpresa!);
      final keys = cfg.acceptedMethods.map((m) => m.key).toList();
      final filtered = getTipoCorridaFiltrado(keys);
      if (mounted) {
        setState(() {
          _empresaConfig = cfg;
          _walletBalance = bal;
          _tiposPermitidos = filtered.isNotEmpty ? filtered : getTipoCorrida();
          _tiposPermitidosGlobal = _tiposPermitidos; // sincroniza global
          _walletBalanceGlobal = bal;
          // Garante que indTipoPgto é um valor da lista filtrada
          if (!_tiposPermitidos.any((t) => t.indTipo == indTipoPgto.indTipo)) {
            indTipoPgto = _tiposPermitidos.first;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Autocomplete via Nominatim — restrito a Canela/Gramado RS
  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    try {
      // Centro fixo: Canela/Gramado RS. GPS da empresa sobrescreve se disponível.
      const double defaultLat = -29.36;
      const double defaultLng = -50.86;
      final double centerLat = ApiBaseHelper.lat != 0.0 ? ApiBaseHelper.lat : defaultLat;
      final double centerLng = ApiBaseHelper.long != 0.0 ? ApiBaseHelper.long : defaultLng;

      // Viewbox ~40km ao redor do centro (cobre Canela + Gramado)
      const delta = 0.35;
      final viewbox =
          '&viewbox=${centerLng - delta},${centerLat + delta},${centerLng + delta},${centerLat - delta}';

      Future<List<Map<String, dynamic>>> doSearch(String bounded) async {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&countrycodes=br&format=json&limit=8&addressdetails=1'
          '$viewbox&bounded=$bounded',
        );
        final res = await http.get(uri, headers: {
          'User-Agent': 'FoolEntregasApp/1.0',
          'Accept-Language': 'pt-BR,pt',
        }).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          return (json.decode(res.body) as List).cast<Map<String, dynamic>>();
        }
        return [];
      }

      // Primeiro tenta restrito à região; se vazio faz fallback sem restrição
      List<Map<String, dynamic>> data = await doSearch('1');
      if (data.isEmpty) data = await doSearch('0');

      if (mounted) setState(() => _suggestions = data);
    } catch (e) {
      // Silencioso — usuário pode pressionar Enter para buscar manualmente
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _fetchSuggestions(value));
  }

  void _selectSuggestion(Map<String, dynamic> item) {
    final address = item['address'] as Map<String, dynamic>? ?? {};
    final road = address['road'] ?? address['pedestrian'] ?? address['street'] ?? '';
    // Se Nominatim não retornou house_number, extrai do texto que o usuário digitou
    String houseNumber = address['house_number']?.toString() ?? '';
    if (houseNumber.isEmpty) {
      final match = RegExp(r'\b(\d+)\b').firstMatch(_controller.text);
      if (match != null) houseNumber = match.group(1) ?? '';
    }
    final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['quarter'] ?? '';
    final city = address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'] ?? '';
    final stateRaw = address['state']?.toString() ?? '';
    final state = stateRaw == 'Rio Grande do Sul' ? 'RS' : stateRaw;

    // Monta endereço legível: "Rua X, 123 - Bairro, Cidade - RS"
    String formatted = road;
    if (houseNumber.isNotEmpty) formatted += ', $houseNumber';
    if (suburb.isNotEmpty) formatted += ' - $suburb';
    if (city.isNotEmpty) formatted += ', $city';
    if (state.isNotEmpty) formatted += ' - $state';
    if (formatted.isEmpty) formatted = item['display_name'] ?? '';

    rua = formatted;
    _controller.text = formatted;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: formatted.length));

    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lng = double.tryParse(item['lon']?.toString() ?? '');

    setState(() {
      _suggestions = [];
      if (lat != null && lng != null) {
        results = [Location(latitude: lat, longitude: lng, timestamp: DateTime.now())];
      }
    });
  }

  // Fallback geocoding manual (quando pressiona Enter / botão buscar)
  Future search() async {
    if (_controller.text.trim().isEmpty) return;
    if (mounted) setState(() => isLoading = true);
    try {
      var r = await locationFromAddress(_controller.text);
      rua = _controller.text;
      if (mounted) setState(() => results = r);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Endereço não encontrado. Tente ser mais específico.')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _buildDisplayAddress(Map<String, dynamic> item) {
    final address = item['address'] as Map<String, dynamic>? ?? {};
    final road = address['road'] ?? address['pedestrian'] ?? '';
    final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
    final suburb = address['suburb'] ?? address['neighbourhood'] ?? '';
    if (road.isNotEmpty && city.isNotEmpty) {
      return suburb.isNotEmpty ? '$road - $suburb, $city' : '$road, $city';
    }
    final dn = (item['display_name'] ?? '') as String;
    return dn.length > 60 ? dn.substring(0, 60) + '...' : dn;
  }

  String _buildSecondaryAddress(Map<String, dynamic> item) {
    final address = item['address'] as Map<String, dynamic>? ?? {};
    final state = address['state'] ?? '';
    final postcode = address['postcode'] ?? '';
    if (postcode.isNotEmpty && state.isNotEmpty) return '$postcode — $state';
    if (state.isNotEmpty) return state;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    contextAux = context;

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: TextField(
              controller: _controller,
              style: GoogleFonts.poppins(fontSize: 14, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: "Rua, número, bairro, cidade...",
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: Color(0xFF9E9E9E)),
                prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () {
                          _controller.clear();
                          setState(() { _suggestions = []; results = []; });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onChanged: _onTextChanged,
              onSubmitted: (_) { _suggestions = []; search(); },
            ),
          ),
        ),
        // Lista de sugestões em tempo real
        if (_suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                final main = _buildDisplayAddress(item);
                final secondary = _buildSecondaryAddress(item);
                return InkWell(
                  onTap: () => _selectSuggestion(item),
                  borderRadius: index == 0
                      ? BorderRadius.vertical(top: Radius.circular(16))
                      : index == _suggestions.length - 1
                          ? BorderRadius.vertical(bottom: Radius.circular(16))
                          : BorderRadius.zero,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.location_on, color: Colors.red, size: 18),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                main,
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (secondary.isNotEmpty)
                                Text(
                                  secondary,
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.north_west, color: Colors.grey.shade300, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        Expanded(child: AddressListView(isLoading, results)),
      ],
    );
  }
}

class SolNovaCorridaPage extends StatefulWidget {
  @override
  _SolNovaCorridaPageState createState() => new _SolNovaCorridaPageState();
}

class _SolNovaCorridaPageState extends State<SolNovaCorridaPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1A1A1A),
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Nova corrida',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          maxLines: 1,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      floatingActionButton: null,
      body: new _NovaCorridaPageState(),
    );
  }
}

Future<List<LatLng>> _createPolylines(iniLat, iniLong, fimLat, fimLong) async {
  // Initializing PolylinePoints
  polylinePoints = PolylinePoints(apiKey: ApiBaseHelper.GEO_KEY);
  polylineCoordinates = [];

  // Generating the list of coordinates to be used for
  // drawing the polylines
  PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
    request: PolylineRequest(
      origin: PointLatLng(iniLat, iniLong), // San Francisco
      destination: PointLatLng(fimLat, fimLong), // San Jose
      mode: TravelMode.driving,
    ),
  );

  // Adding the coordinates to the list
  if (result.points.isNotEmpty) {
    result.points.forEach((PointLatLng point) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    });
  }

  // Defining an ID
  PolylineId id = PolylineId('poly');

  // Initializing Polyline
  Polyline polyline = Polyline(
    polylineId: id,
    color: Colors.red,
    points: polylineCoordinates,
    width: 3,
  );

  // Adding the polyline to the map
  polylines[id] = polyline;
  return polylineCoordinates;
}

double _coordinateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

class AddressTile extends StatefulWidget {
  final Location address;

  const AddressTile({Key? key, required this.address}) : super(key: key);

  @override
  _AddressTile createState() => new _AddressTile();
}

class _AddressTileold extends State<AddressTile> {
  late Location address;
  final titleStyle =
      const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    double lat = ApiBaseHelper.lat;
    double long = ApiBaseHelper.long;
    address = widget.address;

    // double distanceInMeters = Geolocator.distanceBetween(
    //     this.address.latitude, address.longitude, lat, long);

    double distanceInMeters = Geolocator.distanceBetween(
        lat, long, this.address.latitude, address.longitude);

    return FutureBuilder<List<LatLng>?>(
      future:
          _createPolylines(lat, long, this.address.latitude, address.longitude),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return CircularProgressIndicator();
        }

        //TODO precisa ir no painel da google e pegar uma chave para chamar a API de geolocalização
        //Calcular pontos
        double totalDistance = 0.0;

        if (snapshot.connectionState.name == "done") {
// Calculating the total distance by adding the distance
// between small segments
          for (int i = 0; i < polylineCoordinates.length - 1; i++) {
            totalDistance += _coordinateDistance(
              polylineCoordinates[i].latitude,
              polylineCoordinates[i].longitude,
              polylineCoordinates[i + 1].latitude,
              polylineCoordinates[i + 1].longitude,
            );
          }
        } else {
          if (!snapshot.hasData) {
            // while data is loading:
            if (snapshot.connectionState.name == "done") {
// Calculating the total distance by adding the distance
// between small segments
              for (int i = 0; i < polylineCoordinates.length - 1; i++) {
                totalDistance += _coordinateDistance(
                  polylineCoordinates[i].latitude,
                  polylineCoordinates[i].longitude,
                  polylineCoordinates[i + 1].latitude,
                  polylineCoordinates[i + 1].longitude,
                );
              }
            } else {}
          }
        }
        return CircularProgressIndicator();
      },
    );

    double km = distanceInMeters / 1000;
    double kmAux = km;

    //Se for menos que 3.5 usa taxa fixa
    if (kmAux < 3.5) kmAux = 1;

    // return FutureBuilder<double?>(
    //   future: new UserService().getVlrTaxa(kmAux),
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState != ConnectionState.done) {
    //       return CircularProgressIndicator();
    //     }

    //     if (snapshot.connectionState.name == "done") {
    //       var vlrTaxaKm = ApiBaseHelper.userSessao!.configSys!.vlrKmRodado;
    //       var vlrTaxaApp = ApiBaseHelper.userSessao!.configSys!.vlrTaxaApp;
    //       if (vlrTaxaApp == null) vlrTaxaApp = 1.0;

    //       if (snapshot.hasData) vlrTaxaKm = snapshot.data;

    //       if (vlrTaxaKm == null) vlrTaxaKm = 1.0;

    //       double vlr = double.parse(kmAux.toStringAsFixed(2)) * vlrTaxaKm;
    //       double vlrCorrida = 0;
    //       vlrTaxaApp = (vlr * (vlrTaxaApp / 100));
    //       //Nova variavel para controle de valor - foi alterada a regra de totais de corrida para diminuir a taxa.
    //       vlrCorrida = vlr;
    //       vlr = vlr + vlrTaxaApp;

    //       return new Padding(
    //         padding: const EdgeInsets.all(10.0),
    //         child: new Row(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: <Widget>[
    //             Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 new ErrorLabel(
    //                   "feature name",
    //                   "${rua} - " + km.ceilToDouble().toString() + "km",
    //                   fontSize: 15.0,
    //                   isBold: true,
    //                 ),
    //                 new ErrorLabel("address lines",
    //                     "Valor da corrida - R\$ ${vlrCorrida.toStringAsFixed(2)}",
    //                     fontSize: 15.0, isBold: true),
    //               ],
    //             ),
    //             TextButton.icon(
    //               label:
    //                   Text("Solicitar", style: TextStyle(color: Colors.black)),
    //               icon: Icon(
    //                 Icons.add_circle_outline_sharp,
    //                 color: Colors.red[800],
    //               ),
    //               onPressed: () async {
    //                 SolicitacaoMotorista sol = SolicitacaoMotorista();
    //                 sol.qtdKmCorrida = double.parse(km.toStringAsFixed(2));
    //                 sol.vlrTotalMotorista = vlrCorrida - vlrTaxaApp!;
    //                 sol.vlrTaxaRestaurante = vlrCorrida;
    //                 sol.vlrKmRodado = vlrTaxaKm;
    //                 sol.distance = km;
    //                 sol.desLatitudeEntrega = address.latitude;
    //                 sol.desLongitudeEntrega = address.longitude;
    //                 sol.desEnderecoEntrega = rua;
    //                 sol.vlrTaxaApp = vlrTaxaApp;
    //                 //sol.desNumeroEndereco

    //                 showAlertDialog(
    //                   context,
    //                   sol,
    //                 );
    //                 // try {
    //                 //   await UserService().novaCorrida(sol);
    //                 //   final scaffold = ScaffoldMessenger.of(context);
    //                 //   scaffold.showSnackBar(
    //                 //     SnackBar(
    //                 //       content: Text("Corrida solicitada com sucesso"),
    //                 //       action: SnackBarAction(
    //                 //           label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
    //                 //     ),
    //                 //   );

    //                 //   Navigator.pop(context);
    //                 // } on PlatformException catch (e) {
    //                 //   final scaffold = ScaffoldMessenger.of(context);
    //                 //   scaffold.showSnackBar(
    //                 //     SnackBar(
    //                 //       content: Text("Erro ao solicitar corrida"),
    //                 //       action: SnackBarAction(
    //                 //           label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
    //                 //     ),
    //                 //   );
    //                 // }
    //               },
    //             ),
    //             // new ErrorLabel("country name", this.address.countryName),
    //             // new ErrorLabel("locality", this.address.locality),
    //             // new ErrorLabel("sub-locality", this.address.subLocality),
    //             // new ErrorLabel("admin-area", this.address.adminArea),
    //             // new ErrorLabel("sub-admin-area", this.address.subAdminArea),
    //             // new ErrorLabel("thoroughfare", this.address.thoroughfare),
    //             // new ErrorLabel("sub-thoroughfare", this.address.subThoroughfare),
    //             // new ErrorLabel("postal code", this.address.postalCode),
    //             // this.address.coordinates != null
    //             //     ? new ErrorLabel("", this.address.coordinates.toString())
    //             //     : new ErrorLabel("coordinates", null),
    //           ],
    //         ),
    //       );
    //     } else {
    //       if (!snapshot.hasData) {
    //         // while data is loading:
    //         if (snapshot.connectionState.name == "done") {
    //           return Container(
    //               child: Column(
    //             children: <Widget>[
    //               SizedBox(height: 15.0),
    //               TaskColumn(
    //                 icon: Icons.motorcycle,
    //                 title: 'Taxa de corrida não encontrada',
    //                 subtitle: 'Nenhuma informação encontrada',
    //               ),
    //               SizedBox(
    //                 height: 15.0,
    //               ),
    //             ],
    //           ));
    //         } else {}
    //         return Center(
    //           child: CircularProgressIndicator(),
    //         );
    //       }
    //     }
    //     return CircularProgressIndicator();
    //   },
    // );
  }
}

class _AddressTile extends State<AddressTile> with TickerProviderStateMixin {
  late Location address;

  // ── Coordenadas ──────────────────────────────────────────────────────────
  double _originLat = 0.0;
  double _originLng = 0.0;
  double _destLat = 0.0;
  double _destLng = 0.0;

  // ── Estado de carregamento ────────────────────────────────────────────────
  bool _loading = true;
  List<LatLng> _routePoints = [];
  double _km = 0.0;
  double _kmAux = 0.0;
  double _vlrCorrida = 0.0;
  double _vlrTotal = 0.0;
  double? _vlrTaxaKm;
  double? _vlrTaxaApp;

  // (variáveis CoD são geridas localmente no dialog de confirmação)

  // ── Mapa ──────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // ── Moto animada ─────────────────────────────────────────────────────────
  AnimationController? _motoCtrl;
  double _motoProgress = 0.0;
  BitmapDescriptor? _motoIcon;

  @override
  void initState() {
    super.initState();
    address = widget.address;
    _destLat = double.parse(address.latitude.toStringAsPrecision(9));
    _destLng = double.parse(address.longitude.toStringAsPrecision(9));
    _buildMotoIcon();
    _initOriginThenLoad();
  }

  Future<void> _initOriginThenLoad() async {
    await _initOrigin();
    if (!mounted) return;
    try {
      await _loadRouteAndPrice();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Não foi possível calcular o preço da corrida. Verifique as taxas configuradas.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  @override
  void dispose() {
    _motoCtrl?.dispose();
    _mapController = null;
    super.dispose();
  }

  Future<void> _initOrigin() async {
    // 1º: endereço geocodificado da empresa
    final empresa = ApiBaseHelper.userSessao?.usuarioResp?.empresas?.firstOrNull;
    final endEmpresa = empresa?.enderecos?.firstOrNull;

    if (endEmpresa?.desLatitude != null && endEmpresa!.desLatitude != 0.0) {
      _originLat = endEmpresa.desLatitude!;
      _originLng = endEmpresa.desLongitude ?? 0.0;
      return;
    }

    // 2º: coordenadas já em memória (perfil motorista ou GPS atualizado)
    if (ApiBaseHelper.lat != 0.0 && ApiBaseHelper.long != 0.0) {
      _originLat = ApiBaseHelper.lat;
      _originLng = ApiBaseHelper.long;
      return;
    }

    // 3º: GPS real do dispositivo como último recurso
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 6),
      );
      _originLat = pos.latitude;
      _originLng = pos.longitude;
    } catch (_) {
      _originLat = 0.0;
      _originLng = 0.0;
    }
  }

  // ── Carrega rota + preço ─────────────────────────────────────────────────
  Future<void> _loadRouteAndPrice() async {
    final coords =
        await _createPolylines(_originLat, _originLng, _destLat, _destLng);
    if (!mounted) return;

    // Calcula distância real pela rota
    double totalDist = 0.0;
    final pts = coords ?? [];
    for (int i = 0; i < pts.length - 1; i++) {
      totalDist += _coordinateDistance(pts[i].latitude, pts[i].longitude,
          pts[i + 1].latitude, pts[i + 1].longitude);
    }

    // Fallback: distância em linha reta
    final straight =
        Geolocator.distanceBetween(_originLat, _originLng, _destLat, _destLng) /
            1000;
    final km = double.parse(
        (totalDist > 0 ? totalDist : straight).toStringAsFixed(2));
    double kmAux = km;

    // Preço
    final config = ApiBaseHelper.userSessao?.configSys;
    double vlrTaxaKm = (await UserService().getVlrTaxa(kmAux)) ??
        config?.vlrKmRodado ??
        1.0;
    double vlrTaxaApp = config?.vlrTaxaApp ?? 0.0;
    // vlrTaxaKm é taxa FLAT "por corrida" (não por km) — usar diretamente
    final vlr = vlrTaxaKm;
    vlrTaxaApp = vlr * (vlrTaxaApp / 100);

    if (!mounted) return;
    setState(() {
      _routePoints = pts;
      _km = km;
      _kmAux = kmAux;
      _vlrTaxaKm = vlrTaxaKm;
      _vlrTaxaApp = vlrTaxaApp;
      _vlrCorrida = vlr;
      _vlrTotal = vlr + vlrTaxaApp;
      _loading = false;

      // Monta markers e polyline para o mapa
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: const Color(0xFFE53935),
          width: 4,
          points: pts.isNotEmpty
              ? pts
              : [LatLng(_originLat, _originLng), LatLng(_destLat, _destLng)],
          patterns: [],
        ),
      };
      _markers = {
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(_originLat, _originLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Origem'),
        ),
        Marker(
          markerId: const MarkerId('dest'),
          position: LatLng(_destLat, _destLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: rua ?? 'Destino'),
        ),
      };
    });

    _startMotoAnimation();

    // Fit câmera para mostrar origem + destino
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  // ── Ícone da moto (canvas) ────────────────────────────────────────────────
  Future<void> _buildMotoIcon() async {
    const size = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(
        const Offset(size / 2 + 2, size / 2 + 3), size / 2 - 6, shadowPaint);

    // Círculo gradiente vermelho
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(size * 0.2, size * 0.2),
        const Offset(size * 0.8, size * 0.8),
        [const Color(0xFFE53935), const Color(0xFFB71C1C)],
      );
    canvas.drawCircle(
        const Offset(size / 2, size / 2), size / 2 - 4, bgPaint);

    // Anel branco
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 6,
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Emoji 🛵
    final tp = TextPainter(
      text: const TextSpan(text: '🛵', style: TextStyle(fontSize: 26)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(size / 2 - tp.width / 2, size / 2 - tp.height / 2 - 1));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted || data == null) return;

    final icon = BitmapDescriptor.bytes(data.buffer.asUint8List(), width: size);
    setState(() {
      _motoIcon = icon;
      _updateMotoMarker();
    });
  }

  // ── Animação da moto ao longo da rota ────────────────────────────────────
  void _startMotoAnimation() {
    if (_routePoints.length < 2) return;
    final durationSec = (_routePoints.length * 0.12).clamp(6.0, 40.0).round();
    _motoCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: durationSec),
    )..addListener(() {
        if (!mounted) return;
        setState(() {
          _motoProgress = _motoCtrl!.value;
          _updateMotoMarker();
        });
      });
    _motoCtrl!.repeat();
  }

  void _updateMotoMarker() {
    if (_motoIcon == null) return;
    final pos = _getMotoPosition();
    final updated = Set<Marker>.from(
        _markers.where((m) => m.markerId.value != 'moto'));
    updated.add(Marker(
      markerId: const MarkerId('moto'),
      position: pos,
      icon: _motoIcon!,
      zIndexInt: 2,
      anchor: const Offset(0.5, 0.5),
    ));
    _markers = updated;
  }

  LatLng _getMotoPosition() {
    if (_routePoints.isEmpty) return LatLng(_originLat, _originLng);
    final total = _routePoints.length - 1;
    final fi = _motoProgress * total;
    final idx = fi.floor().clamp(0, total - 1);
    final t = fi - idx;
    final a = _routePoints[idx];
    final b = _routePoints[idx + 1 > total ? total : idx + 1];
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  void _fitBounds() {
    if (_mapController == null) return;
    final minLat = _originLat < _destLat ? _originLat : _destLat;
    final maxLat = _originLat > _destLat ? _originLat : _destLat;
    final minLng = _originLng < _destLng ? _originLng : _destLng;
    final maxLng = _originLng > _destLng ? _originLng : _destLng;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.002, minLng - 0.002),
          northeast: LatLng(maxLat + 0.002, maxLng + 0.002),
        ),
        56,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
          ),
        ),
      );
    }

    return Column(
      children: [
        // ── Mapa com rota + moto animada ──────────────────────────────────
        Container(
          height: 230,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  (_originLat + _destLat) / 2,
                  (_originLng + _destLng) / 2,
                ),
                zoom: 13,
              ),
              onMapCreated: (ctrl) {
                _mapController = ctrl;
                _fitBounds();
              },
              markers: _markers,
              polylines: _polylines,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              liteModeEnabled: false,
            ),
          ),
        ),

        // ── Card de info + botão Solicitar ────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Endereço + distância
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDEEEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on,
                        color: Color(0xFFE53935), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rua ?? 'Endereço de entrega',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.straighten_rounded,
                                size: 13, color: Color(0xFF888888)),
                            const SizedBox(width: 4),
                            Text(
                              '$_km km',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF888888)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 14),
              // Valor + botão Solicitar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor estimado',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: const Color(0xFF888888)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'R\$ ${_vlrCorrida.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final sol = SolicitacaoMotorista();
                      sol.qtdKmCorrida = _kmAux;
                      sol.vlrTotalMotorista = _vlrCorrida - (_vlrTaxaApp ?? 0);
                      sol.vlrTaxaRestaurante = _vlrCorrida;
                      sol.vlrKmRodado = _vlrTaxaKm;
                      sol.distance = _km;
                      sol.desLatitudeEntrega = _destLat;
                      sol.desLongitudeEntrega = _destLng;
                      sol.desEnderecoEntrega = rua;
                      sol.vlrTaxaApp = _vlrTaxaApp;
                      showAlertDialog(context, sol, _tiposPermitidosGlobal, _walletBalanceGlobal);
                    },
                    icon: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    label: Text(
                      'Solicitar',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _dropDownItemSelected(TipoCorrida novoItem) {
  indTipoPgto = novoItem;
  _desTipoPgto = novoItem.desTipo;
}

showAlertDialog(
  BuildContext context,
  SolicitacaoMotorista sol, [
  List<TipoCorrida>? tiposPermitidos,
  double walletBalance = 0.0,
]) {
  final _tiposPermitidos = tiposPermitidos ?? getTipoCorrida();
  final _walletBalance = walletBalance;

  final TextEditingController _textFieldControllerObs = TextEditingController();
  final TextEditingController _textFieldControllerComplemento =
      TextEditingController();

  // CoD — estado local ao dialog
  bool _isCod = false;
  bool _indMaquininha = false;
  double _vlrCobrancaCliente = 0.0;
  final TextEditingController _vlrCobrancaCtrl = TextEditingController();

  String? obsEntrega;
  String? complementoEndereco;
  DateTime? dataAgendamento;
  bool _isAgendado = false;
  // set up the buttons
  Widget cancelButton = TextButton(
    child: Text("Cancelar"),
    onPressed: () {
      Navigator.of(context, rootNavigator: false).pop();
    },
  );
  Widget continueButton = TextButton(
    child: Text("Confirmar"),
    onPressed: () async {
      try {
        if (obsEntrega == null || obsEntrega!.trim().isEmpty) {
          LoginControler.showToast(context,
              "Necessário adicionar o nome do cliente: Telefone de contato, quem irá receber e etc...");
          return;
        }

        if (_isAgendado && dataAgendamento == null) {
          LoginControler.showToast(context, "Selecione a data e horário do agendamento.");
          return;
        }

        sol.desObsCorrida = obsEntrega;
        sol.desComplemento = complementoEndereco;
        sol.indTipoCorrida = indTipoPgto.indTipo;
        sol.dthAgendamento = dataAgendamento;
        // CoD
        if (_isCod && _vlrCobrancaCliente > 0) {
          sol.indCobrancaEntrega = 1;
          sol.vlrCobrancaCliente = _vlrCobrancaCliente;
          sol.indMaquininha = _indMaquininha ? 1 : 0;
        }

        // Fecha o dialog de confirmação
        if (context.mounted) {
          Navigator.of(context, rootNavigator: false).pop();
        }

        // ── Payment gate ──────────────────────────────────────────────
        // indTipo: 1=Cartão, 2=Dinheiro, 3=Pix, 4=Boleto, 5=Carteira
        final bool isPix = indTipoPgto.indTipo == 3;
        final bool isCard = indTipoPgto.indTipo == 1;
        final bool isCarteira = indTipoPgto.indTipo == 5;
        final bool isBoleto = indTipoPgto.indTipo == 4;
        final double valorCorrida = sol.vlrTaxaRestaurante ?? sol.vlrTotalMotorista ?? 0.0;
        final String tempId = 'sol_${DateTime.now().millisecondsSinceEpoch}';
        bool paymentOk = true;

        // Carteira Fool: debita saldo na hora
        if (isCarteira && context.mounted) {
          final emp = ApiBaseHelper.userSessao?.usuarioResp?.empresas?.firstOrNull;
          if (emp?.codEmpresa == null) {
            LoginControler.showToast(context, "Empresa não identificada.");
            return;
          }
          final debited = await EmpresaPaymentService.debitWallet(
            codEmpresa: emp!.codEmpresa!,
            amount: valorCorrida,
            corridaId: tempId,
            description: 'Corrida Fool Entregas',
          );
          if (!debited) {
            if (context.mounted) {
              LoginControler.showToast(
                  context, "Saldo insuficiente na Carteira Fool (R\$ ${_walletBalance.toStringAsFixed(2)}).");
            }
            return;
          }
          paymentOk = true;
        }

        // Boleto: sem pagamento imediato — será cobrado no boleto semanal
        // isBoleto → paymentOk = true (já está true por padrão)

        if (isPix && context.mounted) {
          try {
            DialogBuilder(context).showLoadingIndicator("Gerando PIX...");
            final pixData = await PaymentService.generatePixQrCode(
              amount: valorCorrida,
              description: 'Corrida Fool Entregas',
              corridaId: tempId,
            );
            if (context.mounted) {
              try { DialogBuilder(context).hideOpenDialog(); } catch (_) {}
            }
            if (context.mounted) {
              paymentOk = await Navigator.of(context, rootNavigator: false).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => PixQrCodeScreen(
                        corridaId: tempId,
                        asaasPaymentId: pixData.paymentId,
                        amount: pixData.value,
                        pixCopyPaste: pixData.pixCopyPaste,
                        qrCodeImage: pixData.qrCodeImage,
                      ),
                    ),
                  ) ??
                  false;
            }
          } catch (e) {
            if (context.mounted) {
              try { DialogBuilder(context).hideOpenDialog(); } catch (_) {}
              LoginControler.showToast(context, "Erro ao gerar PIX. Tente novamente.");
            }
            return;
          }
        } else if (isCard && context.mounted) {
          paymentOk = await Navigator.of(context, rootNavigator: false).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CardPaymentScreen(
                    corridaId: tempId,
                    amount: valorCorrida,
                    description: 'Corrida Fool Entregas',
                  ),
                ),
              ) ??
              false;
        }

        if (!paymentOk) {
          if (context.mounted) {
            LoginControler.showToast(
                context, "Pagamento não confirmado. Corrida não solicitada.");
          }
          return;
        }
        // ── Fim payment gate ──────────────────────────────────────────

        if (context.mounted) {
          DialogBuilder(context).showLoadingIndicator("Buscando motoboy...");
        }

        final createdNumSeq = await UserService().novaCorrida(sol);

        // ── Registra CoD no Firestore se aplicável ────────────────────
        if (_isCod && _vlrCobrancaCliente > 0 && createdNumSeq != null) {
          final apiUserCod = ApiBaseHelper.userSessao;
          final empresaCod = apiUserCod?.usuarioResp?.empresas?.firstOrNull;
          try {
            await CodService.createCodDelivery(CodDelivery(
              numSeq: createdNumSeq,
              codEmpresa: empresaCod?.codEmpresa ?? 0,
              empresaName: empresaCod?.desNomeFantasia ?? empresaCod?.desRazaoSocial ?? 'Empresa',
              vlrCobranca: _vlrCobrancaCliente,
              indMaquininha: _indMaquininha,
              createdAt: DateTime.now(),
            ));
          } catch (_) {}
        }

        // Escrita no Firestore com retry (até 3 tentativas)
        final apiUser = ApiBaseHelper.userSessao;
        final empresa = apiUser?.usuarioResp?.empresas?.firstOrNull;
        if (empresa != null) {
          final paymentTypeMap = {1: 'cartao', 2: 'dinheiro', 3: 'pix', 4: 'boleto', 5: 'carteira'};
          final enderecos = empresa.enderecos;
          final endereco = (enderecos != null && enderecos.isNotEmpty)
              ? '${enderecos.first.desRua ?? ''} ${enderecos.first.desNumero ?? ''}, ${enderecos.first.desCidade ?? ''}'
              : (empresa.desNomeFantasia ?? 'Empresa');
          final endEmpresa = enderecos?.firstOrNull;
          final pickupLat = (endEmpresa?.desLatitude != null && endEmpresa!.desLatitude != 0.0)
              ? endEmpresa.desLatitude!
              : (ApiBaseHelper.lat != 0.0 ? ApiBaseHelper.lat : -23.5505);
          final pickupLng = (endEmpresa?.desLongitude != null && endEmpresa!.desLongitude != 0.0)
              ? endEmpresa.desLongitude!
              : (ApiBaseHelper.long != 0.0 ? ApiBaseHelper.long : -46.6333);

          Exception? lastError;
          for (int attempt = 0; attempt < 3; attempt++) {
            try {
              await LiveRideService.createRide(
                empresaId: empresa.codEmpresa?.toString() ?? '',
                empresaName: empresa.desNomeFantasia ?? 'Empresa',
                pickupName: empresa.desNomeFantasia ?? 'Empresa',
                pickupAddress: endereco,
                pickupLat: pickupLat,
                pickupLng: pickupLng,
                deliveryAddress: sol.desEnderecoEntrega ?? '',
                deliveryClientName: sol.desObsCorrida ?? 'Cliente',
                deliveryLat: sol.desLatitudeEntrega ?? -23.5631,
                deliveryLng: sol.desLongitudeEntrega ?? -46.6543,
                notes: sol.desComplemento,
                paymentType: paymentTypeMap[sol.indTipoCorrida] ?? 'pix',
                price: sol.vlrTotalMotorista ?? 0.0,
                distanceKm: sol.qtdKmCorrida ?? 0.0,
                numSeq: createdNumSeq,
              );
              lastError = null;
              break;
            } catch (e) {
              lastError = e is Exception ? e : Exception(e.toString());
              if (attempt < 2) await Future.delayed(const Duration(seconds: 2));
            }
          }
          if (lastError != null) {
            debugPrint('⚠️ Firestore write falhou após 3 tentativas: $lastError');
          }
        }

        try { if (context.mounted) DialogBuilder(context).hideOpenDialog(); } catch (_) {}

        if (context.mounted) {
          LoginControler.showToast(context, "Motoboy solicitado com sucesso!");
        }
      } on PlatformException catch (e) {
        try { if (context.mounted) DialogBuilder(context).hideOpenDialog(); } catch (_) {}
        if (context.mounted) {
          LoginControler.showToast(context, "Erro ao solicitar corrida. Tente novamente.");
        }
      }
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Confirmar"),
    content: SizedBox(
      width: double.maxFinite,
      child: StatefulBuilder(builder: (context, setState) {
        return SingleChildScrollView(
         child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            child: Column(
              children: <Widget>[
                Text("Forma de pagamento"),
                DropdownButton<TipoCorrida>(
                  items: _tiposPermitidos.map((dropDownStringItem) {
                    return creatOption(dropDownStringItem);
                  }).toList(),
                  onChanged: (TipoCorrida? novoItemSelecionado) {
                    _dropDownItemSelected(novoItemSelecionado!);
                    isEditado = true;
                    setState(() {
                      indTipoPgto;
                      indTipoPgto.desTipo;
                    });
                  },
                  value: _tiposPermitidos.any((t) => t.indTipo == indTipoPgto.indTipo)
                      ? indTipoPgto
                      : _tiposPermitidos.first,
                ),
                // Aviso de saldo quando Carteira selecionada
                if (indTipoPgto.indTipo == 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_rounded,
                            size: 14,
                            color: _walletBalance > 0 ? Colors.green : Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          'Saldo: R\$ ${_walletBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: _walletBalance > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                // Aviso de boleto semanal
                if (indTipoPgto.indTipo == 4)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '📄 Cobrado no boleto semanal',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ),
          TextFormField(
            onChanged: (value) {
              obsEntrega = value;
            },
            controller: _textFieldControllerObs,
            decoration: InputDecoration(hintText: "Nome do cliente"),
            validator: (value) {
              if (value == null) {
                LoginControler.showToast(context,
                    "Necessário adicionar o nome do cliente: Telefone de contato, quem irá receber e etc...");
                return "Necessário adicionar o nome do cliente: Telefone de contato, quem irá receber e etc...";
              }
              return null;
            },
          ),
          TextField(
            onChanged: (value) {
              complementoEndereco = value;
            },
            controller: _textFieldControllerComplemento,
            decoration: InputDecoration(hintText: "Complemento do endereço"),
          ),
          SizedBox(height: 16),
          // ── Cobrança na Entrega ────────────────────────────────────
          const Divider(height: 24),
          Row(
            children: [
              Checkbox(
                value: _isCod,
                activeColor: const Color(0xFFE53935),
                onChanged: (v) => setState(() {
                  _isCod = v ?? false;
                  if (!_isCod) {
                    _vlrCobrancaCtrl.clear();
                    _vlrCobrancaCliente = 0;
                    _indMaquininha = false;
                  }
                }),
              ),
              const Expanded(
                child: Text(
                  '💰 Cobrança na Entrega (cliente paga ao motorista)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (_isCod) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _vlrCobrancaCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Valor a cobrar (R\$)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                setState(() => _vlrCobrancaCliente = parsed);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _indMaquininha,
                  activeColor: const Color(0xFFE53935),
                  onChanged: (v) => setState(() => _indMaquininha = v ?? false),
                ),
                const Text('Motorista levará maquininha', style: TextStyle(fontSize: 13)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                '⏱ O motorista tem 60 min após a entrega para devolver o dinheiro.',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
              ),
            ),
          ],

          // ── Agendamento ───────────────────────────────────────────
          const Divider(height: 24),
          Row(
            children: [
              Checkbox(
                value: _isAgendado,
                activeColor: const Color(0xFF3949AB),
                onChanged: (v) => setState(() {
                  _isAgendado = v ?? false;
                  if (!_isAgendado) dataAgendamento = null;
                }),
              ),
              const Expanded(
                child: Text(
                  '🕐 Agendar para depois',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (_isAgendado) ...[
            const SizedBox(height: 8),
            // Botão para selecionar data e hora
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(
                dataAgendamento == null
                    ? 'Selecionar data e horário'
                    : '${dataAgendamento!.day.toString().padLeft(2,'0')}/${dataAgendamento!.month.toString().padLeft(2,'0')}/${dataAgendamento!.year}  ${dataAgendamento!.hour.toString().padLeft(2,'0')}:${dataAgendamento!.minute.toString().padLeft(2,'0')}',
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3949AB),
                side: const BorderSide(color: Color(0xFF3949AB)),
              ),
              onPressed: () async {
                final now = DateTime.now();
                final minDate = now.add(const Duration(minutes: 10));

                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: dataAgendamento ?? minDate,
                  firstDate: minDate,
                  lastDate: now.add(const Duration(days: 30)),
                  helpText: 'Selecione a data de coleta',
                  locale: const Locale('pt', 'BR'),
                );
                if (pickedDate == null) return;

                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: dataAgendamento != null
                      ? TimeOfDay(hour: dataAgendamento!.hour, minute: dataAgendamento!.minute)
                      : TimeOfDay(hour: now.hour + 1, minute: 0),
                  helpText: 'Selecione o horário de coleta',
                );
                if (pickedTime == null) return;

                setState(() {
                  dataAgendamento = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                });
              },
            ),
            if (dataAgendamento != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Motorista será notificado 15 min antes de ${dataAgendamento!.hour.toString().padLeft(2,'0')}:${dataAgendamento!.minute.toString().padLeft(2,'0')} para buscar no horário certo.',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          ],
         ),
        );
      }),
    ),
    actions: [
      cancelButton,
      continueButton,
    ],
  );
  // show the dialog

  showDialog(
    context: context,
    useRootNavigator: false,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

class AddressListView extends StatelessWidget {
  final List<Location> addresses;

  final bool isLoading;

  AddressListView(this.isLoading, this.addresses);

  @override
  Widget build(BuildContext context) {
    if (this.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
        ),
      );
    }

    if (this.addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.motorcycle_rounded,
              size: 72,
              color: Color(0xFFD0D0D0),
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum endereço encontrado',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Digite um endereço válido para buscar.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Color(0xFF777777),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 16),
      itemCount: this.addresses.length,
      itemBuilder: (c, i) => new AddressTile(address: this.addresses[i]),
    );
  }
}

class ErrorLabel extends StatelessWidget {
  final String name, text;

  final TextStyle descriptionStyle;

  ErrorLabel(this.name, String text,
      {double fontSize = 9.0, bool isBold = false})
      : this.text = text,
        this.descriptionStyle = new TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: text == null ? Colors.red : Colors.black);

  @override
  Widget build(BuildContext context) {
    return new Text(this.text, style: descriptionStyle);
  }
}
