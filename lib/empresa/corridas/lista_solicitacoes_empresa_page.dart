import 'dart:developer';

import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/empresa/corridas/lista_solicitacoes_empresa_controller.dart';
import 'package:delivery_front/home/widgets/maps/mapsSheet.dart';
import 'package:delivery_front/modules/rating/services/rating_automatic_service.dart';
import 'package:delivery_front/modules/tracking/services/tracking_service.dart';
import 'package:delivery_front/shared/components/Utils.dart';
import 'package:delivery_front/shared/components/filter/filterscreen.dart';
import 'package:delivery_front/shared/models/TipoCorrida.dart';
import 'package:delivery_front/shared/dialogs/cancel_corrida_dialog.dart';
import 'package:delivery_front/shared/models/consultaRequest.dart';
import 'package:flutter/material.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/login/login_controller.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:geocoding/geocoding.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class ListaSolicitacoesEmpresaPage extends StatefulWidget {
// Declare a field that holds the Todo.
  final int? indTipoDefault;

  // In the constructor, require a Todo.
  ListaSolicitacoesEmpresaPage({Key? key, this.indTipoDefault})
      : super(key: key);

  @override
  _ListaSolicitacoesEmpresaPageState createState() =>
      _ListaSolicitacoesEmpresaPageState();
}

class _ListaSolicitacoesEmpresaPageState
    extends State<ListaSolicitacoesEmpresaPage> {
  ListaSolicitacoesEmpresaController? _controller;
  ConsultaRequest? req = ConsultaRequest(
      dtaIni: ApiBaseHelper.findFirstDateOfTheWeek(DateTime.now()),
      dtaFim: ApiBaseHelper.findLastDateOfTheWeek(DateTime.now()));

  @override
  void initState() {
    super.initState();
    _controller = ListaSolicitacoesEmpresaController(context);
    req!.dtaIni = ApiBaseHelper.findFirstDateOfTheWeek(DateTime.now());
    req!.dtaFim = ApiBaseHelper.findLastDateOfTheWeek(DateTime.now());
    _controller!.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context, true);
        return Future<bool>.value(true);
      },
      child: Scaffold(
        floatingActionButton: null, // Removido FAB - botão de filtro será colocado na AppBar
        backgroundColor: Color(0xFFF8F6FB),
        drawer: Drawer(
          backgroundColor: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header do drawer pode ser adicionado aqui se necessário
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Builder(
            builder: (BuildContext context) {
              return Container(
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
              );
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                        widget.indTipoDefault
                    ? 'Novas corridas'
                    : 'Minhas corridas'),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                maxLines: 1,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
              if (req!.dtaIni != null || req!.dtaFim != null)
                Text(
                  ((req!.dtaIni != null
                          ? 'Data Inicial: ${ApiBaseHelper.getDtaFormatadaSemHora(req!.dtaIni)}'
                          : '') +
                      (req!.dtaFim != null
                          ? ' Data final: ${ApiBaseHelper.getDtaFormatadaSemHora(req!.dtaFim)}'
                          : '')),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Color(0xFF777777),
                  ),
                  maxLines: 1,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: Color(0xFF1A1A1A),
                  size: 20,
                ),
                onPressed: () async {
                  var result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => FilterScreen()),
                  );
                  if (mounted) {
                    setState(() {
                      log("Filter values selected in Previous Screen\n ${result}");
                      if (result != null) req = ConsultaRequest.fromJson(result);
                    });
                  }
                },
                tooltip: "Filtrar",
              ),
            ),
          ],
        ),
        body: Center(
            child: ListaCemMotoristaView(
          controller: _controller!,
          indStatusDefault: widget.indTipoDefault,
          req: req,
        )),
      ),
    );
  }
}

class ListaCemMotoristaView extends StatelessWidget {
  final ListaSolicitacoesEmpresaController controller;
  final int? indStatusDefault;
  ConsultaRequest? req;

  ListaCemMotoristaView(
      {Key? key, required this.controller, this.indStatusDefault, this.req})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SolicitacaoMotorista>>(
      future: controller.buscaListaSolicitacoes(
          indBuscaChamadosRaio: indStatusDefault ?? -1, req: req),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<SolicitacaoMotorista> data = snapshot.data!;

          if (data != null && !data.isEmpty) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                ),
              );
            }

            final route = ModalRoute.of(context);
            final pageName = route?.settings.name ?? "";
            log(pageName);
            return _jobsListView(data, controller);
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.motorcycle_rounded,
                    size: 64,
                    color: Color(0xFF9E9E9E),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma corrida encontrada',
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
                      'Ainda não existem registros para este filtro.',
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
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return CircularProgressIndicator();
      },
    );
  }

  ListView _jobsListView(List<SolicitacaoMotorista> data, controller) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          return _tile2(
              ((data[index].dbEmpresasByCodEmpresa?.desNomeFantasia != null
                      ? data[index].dbEmpresasByCodEmpresa!.desNomeFantasia! +
                          " - "
                      : "") +
                  ApiBaseHelper.getDtaFormatada(data[index].dthSolicitacao)),
              (data[index].indStatusCorrida == 1 ? "Concluída" : "Aberta"),
              ((data[index].dbMotoristasByCodMotorista?.desNomeFantasia != null
                      ? data[index]
                              .dbMotoristasByCodMotorista!
                              .desNomeFantasia! +
                          " - "
                      : "") +
                  ApiBaseHelper.getDtaFormatada(data[index].dthAceite)),
              (Utils.getIconStatusCorridaIconData(
                  data[index].indStatusCorrida)),
              data[index],
              controller,
              data[index].indStatusCorrida ==
                          ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA ||
                      data[index].indStatusCorrida ==
                          ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA
                  ? true
                  : false,
              context);
        });
  }

  Widget _tile2(
      String title,
      String subtitle,
      String desMotorista,
      IconData icon,
      SolicitacaoMotorista amigo,
      ListaSolicitacoesEmpresaController _controller,
      bool isFinalizado,
      BuildContext _context) {
    int nextStatus =
        Utils.getDesStatusProxStatusCorrida(amigo.indStatusCorrida);
    String text = Utils.getDesStatusCorrida(amigo.indStatusCorrida);
    subtitle = Utils.getDesTextoProxStatusCorrida(amigo.indStatusCorrida);
    int tipoProcesso = amigo.indStatusCorrida!;
    if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
        amigo.indStatusCorrida) {
      subtitle = "Cancelar";
      tipoProcesso = ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA;
    }

    if (ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA == nextStatus) {
      // subtitle = "Iniciada";
    }
    String subtitleaux = "";
    String subtitleEndere = "";
    String subtitleObsEntrega = "";
    if (amigo.dthInicioCorrida != null)
      subtitleaux = subtitleaux +
          "Inicio corrida:" +
          ApiBaseHelper.getDtaFormatada(amigo.dthInicioCorrida);

    if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
        amigo.indStatusCorrida) {
      if (amigo.enderecoEmpresa != null)
        subtitleEndere = subtitleEndere + amigo.enderecoEmpresa!;

      if (amigo.desObsCorrida != null)
        subtitleObsEntrega = subtitleObsEntrega + amigo.desObsCorrida!;
    } else {
      if (amigo.dthFinalizacaoCorrida != null)
        subtitleaux = subtitleaux +
            " - Fim corrida:" +
            ApiBaseHelper.getDtaFormatada(amigo.dthFinalizacaoCorrida);

      if (amigo.desEnderecoEntrega != null)
        subtitleEndere = subtitleEndere + amigo.desEnderecoEntrega! + " - ";
      //+ amigo.desNumeroEndereco!;

      if (amigo.desObsCorrida != null)
        subtitleObsEntrega = subtitleObsEntrega + amigo.desObsCorrida!;
    }

    if (amigo.indTipoCorrida != null) {
      subtitleObsEntrega = subtitleObsEntrega +
          " - " +
          getTitleTipoCorrida(amigo.indTipoCorrida!);
    }
    subtitleObsEntrega =
        subtitleObsEntrega + ' - R\$ ${amigo.vlrTaxaRestaurante ?? 0}';
    return _customListItem(
      IconButton(
          onPressed: () {},
          icon: Utils.getIconStatusCorrida(amigo.indStatusCorrida)),
      title,
      desMotorista,
      text,
      amigo.qtdKmCorrida ?? 0,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          //Text(subtitle),
            ElevatedButton(
            onPressed: () {
              if (ApiBaseHelper.userSessao!.indTipo ==
                  ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA) {
                if (isFinalizado) {
                  LoginControler.showToast(_context,
                      "Não é possível alterar o status de uma corrida já encerrada.");
                } else {
                  if (ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA ==
                      tipoProcesso) {
                    showAlertDialog(
                        _context, amigo.numSeq!, _controller, tipoProcesso, amigo);
                  } else {
                    LoginControler.showToast(
                        _context, "Aguardando motorista encerrar a corrida.");
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Utils.getColorStatusCorrida(tipoProcesso),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      subtitleaux,
      subtitleEndere,
      subtitleObsEntrega,
      Visibility(
        visible: (amigo.indStatusCorrida ==
                    ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO ||
                amigo.indStatusCorrida ==
                    ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA)
            ? true
            : false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Botão Rastrear (novo)
            if (amigo.codMotorista != null)
              Container(
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                  tooltip: 'Rastrear motorista',
                  onPressed: () async {
                    // Busca última localização conhecida do motorista
                    final lastLocation = await TrackingService.getLastLocationFromFirestore(
                      amigo.numSeq.toString(),
                    );
                    
                    // Tenta usar última localização do Firestore, senão usa endereço de entrega
                    final initialLat = lastLocation?.latitude ?? 
                        (amigo.desLatitudeEntrega ?? 0.0);
                    final initialLng = lastLocation?.longitude ?? 
                        (amigo.desLongitudeEntrega ?? 0.0);
                    
                    if (initialLat != 0.0 && initialLng != 0.0) {
                      Navigator.pushNamed(
                        _context,
                        AppRoutes.liveTracking,
                        arguments: {
                          'corridaId': amigo.numSeq.toString(),
                          'trackedUserId': amigo.codMotorista.toString(),
                          'initialLatitude': initialLat,
                          'initialLongitude': initialLng,
                        },
                      );
                    } else {
                      LoginControler.showToast(
                        _context,
                        'Localização do motorista ainda não disponível. Aguarde alguns instantes.',
                      );
                    }
                  },
                ),
              ),
            // Botão Localização (existente)
            Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                onPressed: () async {
                // Add your onPressed code here!
                //Caso no momento do clique já possua acesso, ao clicar será retirado acesso
                //Caso não tenha acesso, ao ser clicar enviara true para atualizar
                final availableMaps = await Utils.getInstalledMaps();
                // print(
                //     availableMaps); // [AvailableMap { mapName: Google Maps, mapType: google }, ...]

                // await availableMaps.first.showDirections(
                //     destination: map.Coords(37.759392, -122.5107336));
                // MapsSheet.show(
                //   context: context,
                //   onMapTap: (map) {
                //     map.showDirections(
                //       destination: mapN.Coords(-29.1860583, -51.2377713),
                //     );
                //   },
                // );

                if (ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ==
                        amigo.indStatusCorrida! ||
                    ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                        amigo.indStatusCorrida!) {
                  List<Location>? locations = null;
                  if (amigo.dbEmpresasByCodEmpresa!.desLatitude != null ||
                      amigo.dbEmpresasByCodEmpresa!.desLongitude != null) {
                    //Caso latitude ou longitude sejam nulas procura atraves do endereço
                    //  locations = await Utils.getLocationByAddress(
                    //      amigo.desEnderecoEntrega! + "," + amigo.desNumeroEndereco!);

                    if (locations == null) {
                      // Location local2 = locations.first;

                      // amigo.desLongitudeEntrega = local2.longitude;
                      //
                    }

                    if (amigo.dbEmpresasByCodEmpresa!.desLatitude != null &&
                        amigo.dbEmpresasByCodEmpresa!.desLongitude != null) {
                      MapsSheet.show(
                        context: _context,
                        onMapTap: (map) {
                          map.showDirections(
                            destinationTitle:
                                "${amigo.enderecoEmpresa} , - Pedido retirada",
                            destination: Coords(amigo.desLatitudeEntrega!,
                                amigo.desLongitudeEntrega!),
                          );
                        },
                      );
                    } else {
                      Utils.getSnackBar(
                          "Não  é possível iniciar navegação. Motivo: Faltam informações do endereço",
                          _context);
                    }
                  }
                } else {
                  List<Location>? locations = null;
                  if (amigo.desLatitudeEntrega == null ||
                      amigo.desLongitudeEntrega == null) {
                    //Caso latitude ou longitude sejam nulas procura atraves do endereço
                    //  locations = await Utils.getLocationByAddress(
                    //      amigo.desEnderecoEntrega! + "," + amigo.desNumeroEndereco!);

                    locations = await locationFromAddress(
                        amigo.desEnderecoEntrega! +
                            "," +
                            amigo.desNumeroEndereco!);

                    if (locations != null) {
                      Location local2 = locations.first;

                      amigo.desLongitudeEntrega = local2.longitude;
                      amigo.desLatitudeEntrega = local2.latitude;
                    }
                  }

                  if (amigo.desLatitudeEntrega != null &&
                      amigo.desLongitudeEntrega != null) {
                    MapsSheet.show(
                      context: _context,
                      onMapTap: (map) {
                        map.showDirections(
                          destinationTitle:
                              "${amigo.desEnderecoEntrega} , ${amigo.desNumeroEndereco} - Entrega",
                          destination: Coords(amigo.desLatitudeEntrega!,
                              amigo.desLongitudeEntrega!),
                        );
                      },
                    );
                  } else {
                    Utils.getSnackBar(
                        "Não  é possível iniciar navegação. Motivo: Faltam informações do endereço",
                        _context);
                  }
                }
                // bool? existe = await mapN.MapLauncher.isMapAvailable(
                //     mapN.MapType.google);
                // if (existe!) {
                //   await mapN.MapLauncher.showDirections(
                //       mapType: mapN.MapType.google,
                //       destination: mapN.Coords(37.759392, -122.5107336));
                // }

                // existe = await mapN.MapLauncher.isMapAvailable(
                //     mapN.MapType.waze);
                // if (existe!) {
                //   await mapN.MapLauncher.showDirections(
                //       mapType: mapN.MapType.waze,
                //       destination: mapN.Coords(37.759392, -122.5107336));
                // }

                //  await availableMaps.first.showMarker(
                //    coords: Coords(
                //        amigo.desLatitudeEntrega!, amigo.desLongitudeEntrega!),
                //    title: "${amigo.desEnderecoEntrega} , ${amigo.desNumeroEndereco} - Entrega",
                //  );
              },
              ),
            ),
          ],
        ),
      ),
      SizedBox.shrink(), // custom3 - não usado na nova implementação
    );
  }

  _customListItem(
    Widget thumbnail,
    String title,
    String desMotorista,
    String? user,
    double viewCount,
    Widget custom,
    String dadosCorrida,
    String enderecoEntrega,
    String obsEntrega,
    Widget custom2,
    Widget custom3,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                  decoration: BoxDecoration(
                  color: Color(0xFFFDEEEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.motorcycle,
                  color: Colors.red,
                  size: 26,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _videoDescription(title, user ?? "", viewCount, dadosCorrida,
                    enderecoEntrega, obsEntrega, desMotorista),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (custom2 is Visibility && custom2.visible) custom2,
              SizedBox(width: 8),
              custom,
            ],
          ),
        ],
      ),
    );
  }

  _videoDescription(
      String title,
      String user,
      double viewCount,
      String dadosCorrida,
      String enderecoEntrega,
      String obsEntrega,
      String desMotorista) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16.0,
            color: Color(0xFF1A1A1A),
            height: 1.1,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          textAlign: TextAlign.left,
        ),
        if (user.isNotEmpty) ...[
          SizedBox(height: 6),
          Text(
            user,
            style: GoogleFonts.poppins(
              fontSize: 14.0,
              color: Color(0xFF777777),
            ),
          ),
        ],
        if (dadosCorrida.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            dadosCorrida,
            style: GoogleFonts.poppins(
              fontSize: 12.0,
              color: Color(0xFF777777),
            ),
          ),
        ],
        if (enderecoEntrega.isNotEmpty) ...[
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF777777)),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  enderecoEntrega,
                  style: GoogleFonts.poppins(
                    fontSize: 12.0,
                    color: Color(0xFF777777),
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ],
        if (obsEntrega.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            obsEntrega,
            style: GoogleFonts.poppins(
              fontSize: 12.0,
              color: Color(0xFF777777),
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            textAlign: TextAlign.left,
          ),
        ],
        if (desMotorista.isNotEmpty) ...[
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_rounded, size: 14, color: Color(0xFF777777)),
              SizedBox(width: 4),
              Text(
                desMotorista,
                style: GoogleFonts.poppins(
                  fontSize: 12.0,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        ],
        if (viewCount > 0) ...[
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.straighten_rounded, size: 14, color: Color(0xFF777777)),
              SizedBox(width: 4),
              Text(
                '${viewCount.toStringAsFixed(1)} km',
                style: GoogleFonts.poppins(
                  fontSize: 12.0,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  ListTile _tile(
      String title,
      String subtitle,
      IconData icon,
      SolicitacaoMotorista amigo,
      ListaSolicitacoesEmpresaController _controller,
      bool isFinalizado,
      BuildContext _context) {
    subtitle = Utils.getDesStatusCorrida(amigo.indStatusCorrida);
    String subtitleaux = subtitle;
    int tipoProcesso = amigo.indStatusCorrida!;
    if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
        amigo.indStatusCorrida) {
      subtitle = "Cancelar";
      tipoProcesso = amigo.indStatusCorrida!;
    }

    if (amigo.dthInicioCorrida != null)
      subtitleaux = subtitleaux +
          " Inicio corrida:" +
          ApiBaseHelper.getDtaFormatada(amigo.dthInicioCorrida);
    return ListTile(
      contentPadding: const EdgeInsets.all(15.0),
      title: Text(title, style: TextStyle()),
      subtitle: Text(
        subtitleaux,
        style: TextStyle(color: Colors.black),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          //Text(subtitle),
          FloatingActionButton.extended(
            onPressed: () {
              // Add your onPressed code here!
              //Caso no momento do clique já possua acesso, ao clicar será retirado acesso
              //Caso não tenha acesso, ao ser clicar enviara true para atualizar
              if (ApiBaseHelper.userSessao!.indTipo ==
                  ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
                if (isFinalizado) {
                  LoginControler.showToast(_context,
                      "Não é possível alterar o status de uma corrida já encerrado.");
                } else {
                  //amigo.indStatusCorrida = (isFinalizado ? 1 : 0);
                  //_controller.finalizarChamado(amigo.numSeq!,ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA );
                  showAlertDialog(_context, amigo.numSeq!, _controller, 4, amigo);
                  //amigo.indStatusCorrida = Utils.getDesStatusProxStatusCorrida(amigo.indStatusCorrida);
                }
              }
            },
            label: Text(subtitle, style: TextStyle(fontSize: 10)),
            icon: Utils.getIconStatusCorrida(amigo.indStatusCorrida),
            backgroundColor: (isFinalizado ? Colors.green : Colors.red),
          ),
        ],
      ),
      isThreeLine: true,
      leading: Icon(
        icon,
        color: Colors.orange[500],
      ),
    );
  }

  showAlertDialog(
      BuildContext _context,
      int numSeqChamado,
      ListaSolicitacoesEmpresaController _controller,
      int indStatusAtualCorrida,
      SolicitacaoMotorista solicitacao) {
    int nextStatus = Utils.getDesStatusProxStatusCorrida(indStatusAtualCorrida);
    String text = Utils.getDesTextoProxStatusCorrida(indStatusAtualCorrida);
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancelar"),
      onPressed: () {
        Navigator.of(_context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Confirmar"),
      onPressed: () async {
        if (ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA ==
            indStatusAtualCorrida) {
          // Fecha o dialog atual
          Navigator.of(_context).pop();
          
          // Abre dialog de cancelamento com motivo obrigatório
          final motivo = await CancelCorridaDialog.show(
            _context,
            corridaId: numSeqChamado.toString(),
            tituloCorrida: solicitacao.desEnderecoEntrega ?? 'Corrida #$numSeqChamado',
          );
          
          // Se motivo foi fornecido, cancela a corrida
          if (motivo != null && motivo.isNotEmpty) {
            _controller.finalizarChamado(
              numSeqChamado,
              ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA,
              motivoCancelamento: motivo,
            );
          }
        } else {
          if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
              indStatusAtualCorrida) {
            await _controller.aceitarCorrida(numSeqChamado, nextStatus);
            Navigator.of(_context).pop();
            if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                indStatusAtualCorrida) {
              Navigator.pushNamed(
                _context,
                AppRoutes.corridasEmpresa,
                arguments: {
                  'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO,
                },
              );
            } else {
              _controller.finalizarChamado(numSeqChamado, nextStatus);

              Navigator.of(_context).pop();
            }
          } else {
            // Finaliza corrida
            _controller.finalizarChamado(numSeqChamado, nextStatus);
            Navigator.of(_context).pop();
            
            // Se a corrida foi concluída (status 3), abre tela de avaliação
            if (nextStatus == ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA) {
              await Future.delayed(const Duration(milliseconds: 500));
              if (_context.mounted) {
                await RatingAutomaticService.openRatingScreenAfterCompletion(
                  context: _context,
                  corridaId: numSeqChamado.toString(),
                  solicitacao: solicitacao,
                  currentUserType: 'empresa',
                );
              }
            }
          }
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Confirmar"),
      content: Text("Deseja realmente ${text}?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: _context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
