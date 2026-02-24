import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/home/widgets/task_column.dart';
import 'package:delivery_front/login/login_controller.dart';
import 'package:delivery_front/shared/components/loading_dialog.dart';
import 'package:delivery_front/shared/models/TipoCorrida.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/shared/models/destino_corrida.dart';
import 'package:delivery_front/shared/widgets/agendamento_corrida_widget.dart';
import 'package:delivery_front/shared/widgets/multiplos_destinos_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' show cos, sqrt, asin;

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

  bool isLoading = false;

  Future search() async {
    this.setState(() {
      this.isLoading = true;
    });

    try {
      var results = await locationFromAddress(_controller.text);
      rua = _controller.text;
      this.setState(() {
        this.results = results;
      });
    } catch (e) {
      print("Error occured: $e");
    } finally {
      this.setState(() {
        this.isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    contextAux = context;

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    decoration: InputDecoration(
                      hintText: "Digite um endereço",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => search(),
                  ),
                ),
                GestureDetector(
                  onTap: () => search(),
                  child: Icon(
                    Icons.search,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: new AddressListView(this.isLoading, this.results)),
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
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header do drawer pode ser adicionado aqui se necessário
            // Por enquanto, apenas garantir que o drawer existe
          ],
        ),
      ),
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

class _AddressTile extends State<AddressTile> {
  late Location address;
  final titleStyle =
      const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    double lat = ApiBaseHelper.lat;
    double long = ApiBaseHelper.long;
    address = widget.address;

    return new FutureBuilder<List<LatLng>?>(
      future: _createPolylines(
          lat,
          long,
          double.parse(this.address.latitude.toStringAsPrecision(9)),
          double.parse(address.longitude.toStringAsPrecision(9))),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return CircularProgressIndicator();
        }

        //TODO precisa ir no painel da google e pegar uma chave para chamar a API de geolocalização
        //Calcular pontos
        double totalDistance = 0.0;

        if (snapshot.connectionState.name == "done") {
          double distanceInMeters = Geolocator.distanceBetween(
              lat, long, this.address.latitude, address.longitude);

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

          double km = distanceInMeters / 1000;
          km = double.parse(km.toStringAsFixed(2));

          double kmAux = km;
          if (totalDistance > 0) {
            kmAux = double.parse(totalDistance.toStringAsFixed(2));
            km = double.parse(totalDistance.toStringAsFixed(2));
          }

          //Se for menos que 3.5 usa taxa fixa
          if (kmAux < 3.5) kmAux = 1;

          return FutureBuilder<double?>(
            future: new UserService().getVlrTaxa(kmAux),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              }

              if (snapshot.connectionState.name == "done") {
                var vlrTaxaKm =
                    ApiBaseHelper.userSessao!.configSys!.vlrKmRodado;
                var vlrTaxaApp =
                    ApiBaseHelper.userSessao!.configSys!.vlrTaxaApp;
                if (vlrTaxaApp == null) vlrTaxaApp = 1.0;

                if (snapshot.hasData) vlrTaxaKm = snapshot.data;

                if (vlrTaxaKm == null) vlrTaxaKm = 1.0;

                double vlr = kmAux * vlrTaxaKm;
                double vlrCorrida = 0;
                vlrTaxaApp = (vlr * (vlrTaxaApp / 100));
                //Nova variavel para controle de valor - foi alterada a regra de totais de corrida para diminuir a taxa.
                vlrCorrida = vlr;
                vlr = vlr + vlrTaxaApp;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color(0xFFFDEEEE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.motorcycle,
                              color: Colors.red,
                              size: 26,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rua ?? "Endereço",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  textAlign: TextAlign.left,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.straighten_rounded, size: 14, color: Color(0xFF777777)),
                                    SizedBox(width: 4),
                                    Text(
                                      km.toString() + " km",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Color(0xFF777777),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF7F5FA),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Valor da corrida",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Color(0xFF777777),
                                    ),
                                    maxLines: 1,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "R\$ ${vlrCorrida.toStringAsFixed(2)}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                    maxLines: 1,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                SolicitacaoMotorista sol = SolicitacaoMotorista();
                                sol.qtdKmCorrida = kmAux;
                                sol.vlrTotalMotorista = vlrCorrida - vlrTaxaApp!;
                                sol.vlrTaxaRestaurante = vlrCorrida;
                                sol.vlrKmRodado = vlrTaxaKm;
                                sol.distance = km;
                                sol.desLatitudeEntrega = address.latitude;
                                sol.desLongitudeEntrega = address.longitude;
                                sol.desEnderecoEntrega = rua;
                                sol.vlrTaxaApp = vlrTaxaApp;

                                showAlertDialog(
                                  context,
                                  sol,
                                );
                              },
                              icon: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                "Solicitar",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // new ErrorLabel("country name", this.address.countryName),
                      // new ErrorLabel("locality", this.address.locality),
                      // new ErrorLabel("sub-locality", this.address.subLocality),
                      // new ErrorLabel("admin-area", this.address.adminArea),
                      // new ErrorLabel("sub-admin-area", this.address.subAdminArea),
                      // new ErrorLabel("thoroughfare", this.address.thoroughfare),
                      // new ErrorLabel("sub-thoroughfare", this.address.subThoroughfare),
                      // new ErrorLabel("postal code", this.address.postalCode),
                      // this.address.coordinates != null
                      //     ? new ErrorLabel("", this.address.coordinates.toString())
                      //     : new ErrorLabel("coordinates", null),
                    ],
                  ),
                );
              } else {
                if (!snapshot.hasData) {
                  // while data is loading:
                  if (snapshot.connectionState.name == "done") {
                    return Container(
                        child: Column(
                      children: <Widget>[
                        SizedBox(height: 15.0),
                        TaskColumn(
                          icon: Icons.motorcycle,
                          title: 'Taxa de corrida não encontrada',
                          subtitle: 'Nenhuma informação encontrada',
                        ),
                        SizedBox(
                          height: 15.0,
                        ),
                      ],
                    ));
                  } else {}
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              }
              return CircularProgressIndicator();
            },
          );
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
  }
}

void _dropDownItemSelected(TipoCorrida novoItem) {
  indTipoPgto = novoItem;
  _desTipoPgto = novoItem.desTipo;
  _desTipoPgto = "teste";
}

showAlertDialog(BuildContext context, SolicitacaoMotorista sol) {
  final TextEditingController _textFieldControllerObs = TextEditingController();
  final TextEditingController _textFieldControllerComplemento =
      TextEditingController();

  String? obsEntrega;
  String? complementoEndereco;
  DateTime? dataAgendamento;
  bool usarMultiplosDestinos = false;
  List<DestinoCorrida> destinos = [DestinoCorrida(ordem: 1)];
  // set up the buttons
  Widget cancelButton = TextButton(
    child: Text("Cancelar"),
    onPressed: () {
      Navigator.of(contextAux, rootNavigator: true).pop('dialog');
    },
  );
  Widget continueButton = TextButton(
    child: Text("Confirmar"),
    onPressed: () async {
      try {
        if (obsEntrega == null) {
          LoginControler.showToast(contextAux,
              "Necessário selecionar adicionar o nome do cliente: Telefone de contato, quem irá receber e etc...");
        } else {
          sol.desObsCorrida = obsEntrega;
          sol.desComplemento = complementoEndereco;
          sol.indTipoCorrida = indTipoPgto.indTipo;
          sol.dthAgendamento = dataAgendamento; // Adiciona data de agendamento
          
          // Se usar múltiplos destinos, salva a lista
          if (usarMultiplosDestinos && destinos.isNotEmpty) {
            sol.destinos = destinos;
            // Mantém compatibilidade: salva o primeiro destino nos campos antigos
            final primeiroDestino = destinos.first;
            sol.desEnderecoEntrega = primeiroDestino.desEnderecoEntrega;
            sol.desNumeroEndereco = primeiroDestino.desNumeroEndereco;
            sol.desComplemento = primeiroDestino.desComplemento ?? complementoEndereco;
            sol.desLatitudeEntrega = primeiroDestino.desLatitudeEntrega;
            sol.desLongitudeEntrega = primeiroDestino.desLongitudeEntrega;
            sol.desTelefone = primeiroDestino.desTelefone ?? sol.desTelefone;
          }
          
          Navigator.of(contextAux, rootNavigator: true).pop('dialog');

          final scaffold = ScaffoldMessenger.of(contextAux);
          scaffold.showSnackBar(
            SnackBar(
              content: Text("Aguarde... Solicitando corrida..."),
              action: SnackBarAction(
                  label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
            ),
          );
          // await DialogBuilder(contextAux).showLoadingIndicator("");

          await Future.delayed(Duration(seconds: 1));
          await UserService().novaCorrida(sol);

          DialogBuilder(contextAux).hideOpenDialog();

          LoginControler.showToast(
              contextAux, "Sucesso ao solicitar corrida...");

          //DialogBuilder(contextAux).hideOpenDialog();
          //

          //  Navigator.pop(contextAux);
        }
      } on PlatformException catch (e) {
        final scaffold = ScaffoldMessenger.of(contextAux);
        scaffold.showSnackBar(
          SnackBar(
            content: Text("Erro ao solicitar corrida"),
            action: SnackBarAction(
                label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
          ),
        );
      } finally {
        //
      }
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Confirmar"),
    content: StatefulBuilder(builder: (context, setState) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            child: Column(
              children: <Widget>[
                Text("Forma de pagamento"),
                DropdownButton<TipoCorrida>(
                  items: _listTiposCorridas.map((dropDownStringItem) {
                    return creatOption(dropDownStringItem);
                  }).toList(),
                  onChanged: (TipoCorrida? novoItemSelecionado) {
                    _dropDownItemSelected(novoItemSelecionado!);
                    isEditado = true;
                    setState(() {
                      indTipoPgto;
                      indTipoPgto.desTipo;
                      // dropOptions;
                    });
                  },
                  value: indTipoPgto,
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
          // Toggle para múltiplos destinos
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.multiple_stop, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Múltiplos Destinos',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: usarMultiplosDestinos,
                  onChanged: (value) {
                    setState(() {
                      usarMultiplosDestinos = value;
                      if (!value && destinos.length > 1) {
                        destinos = [destinos.first];
                      }
                    });
                  },
                  activeColor: Colors.red,
                ),
              ],
            ),
          ),
          if (usarMultiplosDestinos) ...[
            SizedBox(height: 16),
            MultiplosDestinosWidget(
              destinos: destinos,
              onDestinosChanged: (novosDestinos) {
                setState(() {
                  destinos = novosDestinos;
                });
              },
            ),
          ],
          SizedBox(height: 16),
          AgendamentoCorridaWidget(
            dataAgendamentoInicial: dataAgendamento,
            onDataSelecionada: (DateTime? data) {
              dataAgendamento = data;
            },
          ),
        ],
      );
    }),
    actions: [
      cancelButton,
      continueButton,
    ],
  );
  // show the dialog

  showDialog(
    context: context,
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
