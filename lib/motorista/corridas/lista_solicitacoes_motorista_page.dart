import 'dart:async';
import 'dart:developer';

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/home/widgets/maps/mapsSheet.dart';
import 'package:delivery_front/login/login_controller.dart';
import 'package:delivery_front/motorista/corridas/lista_solicitacoes_motorista_controller.dart';
import 'package:delivery_front/modules/chat/screens/chat_screen.dart';
import 'package:delivery_front/modules/rating/services/rating_automatic_service.dart';
import 'package:delivery_front/shared/components/Utils.dart';
import 'package:delivery_front/shared/models/TipoCorrida.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/shared/dialogs/cancel_corrida_dialog.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

class ListaSolicitacoesMotoristaPage extends StatefulWidget {
// Declare a field that holds the Todo.
  final int? indTipoDefault;
  bool? isAdm;

  // In the constructor, require a Todo.
  ListaSolicitacoesMotoristaPage(
      {Key? key, this.indTipoDefault, this.isAdm = false})
      : super(key: key);

  ListaSolicitacoesMotoristaPage.second(
      {Key? key, this.indTipoDefault, required this.isAdm})
      : super(key: key);

  @override
  _ListaSolicitacoesMotoristaPageState createState() =>
      _ListaSolicitacoesMotoristaPageState();
}

class _ListaSolicitacoesMotoristaPageState
    extends State<ListaSolicitacoesMotoristaPage> {
  ListaSolicitacoesMotoristaController? _controller;
  late VoidCallback _controllerListener;

  @override
  void initState() {
    super.initState();
    _controller = ListaSolicitacoesMotoristaController(context);
    _controllerListener = () { if (mounted) setState(() {}); };
    _controller!.addListener(_controllerListener);
  }

  @override
  void dispose() {
    _controller?.removeListener(_controllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context, true);
        return Future<bool>.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                  widget.indTipoDefault
              ? 'Pedidos disponíveis'
              : ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO ==
                      widget.indTipoDefault
                  ? 'Corridas em andamento'
                  : ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA ==
                          widget.indTipoDefault
                      ? 'Corridas concluídas'
                      : ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA ==
                              widget.indTipoDefault
                          ? 'Corridas canceladas'
                          : 'Minhas corridas'),
        ),
        body: Center(
            child: ListaCemMotoristaView(
          controller: _controller!,
          indStatusDefault: widget.indTipoDefault,
          isAdm: widget.isAdm ?? false,
        )),
      ),
    );
  }
}

class ListaCemMotoristaView extends StatefulWidget {
  final ListaSolicitacoesMotoristaController controller;
  final int? indStatusDefault;
  final bool isAdm;

  ListaCemMotoristaView(
      {Key? key,
      required this.controller,
      this.indStatusDefault,
      this.isAdm = false})
      : super(key: key);

  @override
  State<ListaCemMotoristaView> createState() => _ListaCemMotoristaViewState();
}

class _ListaCemMotoristaViewState extends State<ListaCemMotoristaView> {
  late Future<List<SolicitacaoMotorista>> _future;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh a cada 15 segundos (BUG-006: UI não atualiza status em tempo real)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _future = widget.controller.buscaListaSolicitacoes(
          indBuscaChamadosRaio: widget.indStatusDefault ?? -1,
          isAdm: widget.isAdm);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: FutureBuilder<List<SolicitacaoMotorista>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            List<SolicitacaoMotorista> data = snapshot.data!;
            final route = ModalRoute.of(context);
            final pageName = route?.settings.name ?? "";
            log(pageName);
            if (data.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Text(
                      'Nenhuma corrida encontrada.\nArraste para baixo para atualizar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              );
            }
            return _jobsListView(data, widget.controller);
          } else if (snapshot.hasError) {
            return ListView(
              children: [
                SizedBox(height: 80),
                Center(child: Text("${snapshot.error}")),
              ],
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // ListView _jobsListView(List<SolicitacaoMotorista> data, controller) {
  //   return ListView.builder(
  //       itemCount: data.length,
  //       itemBuilder: (context, index) {
  //         return _tile(
  //             ((data[index].dbMotoristasByCodMotorista!.desNomeFantasia != null
  //                     ? data[index]
  //                             .dbMotoristasByCodMotorista!
  //                             .desNomeFantasia! +
  //                         " - "
  //                     : "") +
  //                 ApiBaseHelper.getDtaFormatada(data[index].dthSolicitacao)),
  //             (data[index].indStatusCorrida == 1 ? "Concluída" : "Aberta"),
  //             (Utils.getIconStatusCorridaIconData(
  //                 data[index].indStatusCorrida)),
  //             data[index],
  //             controller,
  //             data[index].indStatusCorrida ==
  //                     ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA
  //                 ? true
  //                 : false,
  //             context);
  //       });
  // }

  ListView _jobsListView(
      List<SolicitacaoMotorista> data,
      ListaSolicitacoesMotoristaController controller) {
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

  Padding _tile2(
      String title,
      String subtitle,
      IconData icon,
      SolicitacaoMotorista amigo,
      ListaSolicitacoesMotoristaController _controller,
      bool isFinalizado,
      BuildContext _context) {
    int nextStatus =
        Utils.getDesStatusProxStatusCorrida(amigo.indStatusCorrida);
    String text = Utils.getDesStatusCorrida(amigo.indStatusCorrida);
    subtitle = Utils.getDesTextoProxStatusCorrida(amigo.indStatusCorrida);
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

      if (amigo.desEnderecoEntrega != null) {
        subtitleEndere = subtitleEndere + amigo.desEnderecoEntrega!;
        if (amigo.desNumeroEndereco != null && amigo.desNumeroEndereco!.isNotEmpty) {
          subtitleEndere = subtitleEndere + ', ' + amigo.desNumeroEndereco!;
        }
        subtitleEndere = subtitleEndere + ' - ';
      }

      if (amigo.desObsCorrida != null)
        subtitleObsEntrega = subtitleObsEntrega + amigo.desObsCorrida!;
    }

    if (amigo.indTipoCorrida != null) {
      subtitleObsEntrega = subtitleObsEntrega +
          " - " +
          getTitleTipoCorrida(amigo.indTipoCorrida!);
    }

    // Para nova corrida: exibe ganho com label claro no topo das obs
    if (amigo.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA) {
      final ganho = Utils.formatBRL(amigo.vlrTotalMotorista);
      subtitleObsEntrega = '💰 Você recebe: $ganho\n$subtitleObsEntrega';
    } else {
      subtitleObsEntrega = subtitleObsEntrega + ' · ${Utils.formatBRL(amigo.vlrTotalMotorista)}';
    }

    // Build multi-destination steps label when delivery has ordered destinations
    if (amigo.destinos != null && amigo.destinos!.length > 1) {
      final sorted = [...amigo.destinos!]..sort((a, b) => a.ordem.compareTo(b.ordem));
      final steps = sorted
          .map((d) => '${d.ordem}. ${d.enderecoCompleto}')
          .join('\n');
      subtitleEndere = 'Paradas:\n$steps';
    }

    // Botão de chat — visível para corridas aceitas ou em andamento
    final user = ApiBaseHelper.userSessao;
    Widget chatButton = Visibility(
      visible: (amigo.indStatusCorrida ==
                  ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ||
              amigo.indStatusCorrida ==
                  ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO)
          ? true
          : false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'chat_${amigo.numSeq}',
            onPressed: () {
              if (user == null) return;
              final motoristaId =
                  user.usuarioResp?.motoristas?.first.codMotorista?.toString() ??
                      '';
              final motoristaName =
                  user.usuarioResp?.motoristas?.first.desNomeFantasia ??
                      user.desNome ??
                      'Motorista';
              final empresaId =
                  amigo.codEmpresa?.toString() ?? '';
              final empresaName =
                  amigo.dbEmpresasByCodEmpresa?.desNomeFantasia ?? 'Empresa';

              Navigator.push(
                _context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    corridaId: amigo.numSeq?.toString() ?? '',
                    motoristaId: motoristaId,
                    motoristaName: motoristaName,
                    empresaId: empresaId,
                    empresaName: empresaName,
                    currentUserId: motoristaId,
                    currentUserName: motoristaName,
                    currentUserType: 'motorista',
                  ),
                ),
              );
            },
            child: const Icon(Icons.chat_bubble_outline),
            backgroundColor: Colors.green,
          ),
        ],
      ),
    );

    return _customListItem(
      IconButton(
          onPressed: () {},
          icon: Utils.getIconStatusCorrida(amigo.indStatusCorrida)),
      title,
      text,
      amigo.qtdKmCorrida ?? 0,
      Row(
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
                      "Não é possível alterar o status de uma corrida já encerrada.");
                } else {
                  //amigo.indStatusCorrida = (isFinalizado ? 1 : 0);
                  //_controller.finalizarChamado(amigo.numSeq!,ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA );
                  if (ApiBaseHelper.userSessao?.usuarioResp?.indBloqueado !=
                          null &&
                      ApiBaseHelper.userSessao?.usuarioResp?.indBloqueado ==
                          1) {
                    LoginControler.showToast(_context,
                        "Usuário bloqueado não é possível aceitar corridas.");
                  } else {
                    showAlertDialog(_context, amigo.numSeq!, _controller,
                        amigo.indStatusCorrida!, amigo);
                    //amigo.indStatusCorrida = Utils.getDesStatusProxStatusCorrida(amigo.indStatusCorrida);
                  }
                }
              }
            },
            label: Text(subtitle, style: TextStyle(fontSize: 8)),
            //  icon: Utils.getIconStatusCorrida(amigo.indStatusCorrida),
            backgroundColor:
                Utils.getColorStatusCorrida(amigo.indStatusCorrida),
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
            //Text(subtitle),
            FloatingActionButton(
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
                            destination: Coords(
                                amigo.dbEmpresasByCodEmpresa!.desLatitude!,
                                amigo.dbEmpresasByCodEmpresa!.desLongitude!),
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
              //label: Text("", style: TextStyle(fontSize: 8)),
              child: Icon(Icons.location_on),
              //icon: Icon(Icons.location_on),
              backgroundColor: Colors.blue,
            ),
          ],
        ),
      ),
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
            //Text(subtitle),
            FloatingActionButton(
              onPressed: () async {
                // Add your onPressed code here!
                //Caso no momento do clique já possua acesso, ao clicar será retirado acesso
                //Caso não tenha acesso, ao ser clicar enviara true para atualizar
                if (amigo.desTelefone != null) {
                  String telefone = amigo.desTelefone!;
                  String url = "tel:$telefone";
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                }
              },
              //label: Text("", style: TextStyle(fontSize: 8)),
              child: Icon(Icons.call),
              //icon: Icon(Icons.location_on),
              backgroundColor: Colors.blue,
            ),
          ],
        ),
      ),
      chatButton,
    );
  }

  _customListItem(
      Widget thumbnail,
      String title,
      String? user,
      double viewCount,
      Widget custom,
      String dadosCorrida,
      String enderecoEntrega,
      String obsEntrega,
      Widget custom2,
      Widget custom3,
      Widget custom4) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [thumbnail],
          ),
          Expanded(
            flex: 3,
            child: _videoDescription(title, user ?? "", viewCount, dadosCorrida,
                enderecoEntrega, obsEntrega),
          ),
          custom,
          custom2,
          custom3,
          custom4,
        ],
      ),
    );
  }

  _videoDescription(String title, String user, double viewCount,
      String dadosCorrida, String enderecoEntrega, String obsEntrega) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5.0, 0.0, 0.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14.0,
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 2.0)),
          Text(
            user,
            style: const TextStyle(fontSize: 10.0),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 2.0)),
          Text(
            dadosCorrida,
            style: const TextStyle(fontSize: 10.0),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Text(
            enderecoEntrega,
            style: const TextStyle(fontSize: 10.0),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Text(
            obsEntrega,
            style: const TextStyle(fontSize: 10.0),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Text(
            '$viewCount KMs',
            style: const TextStyle(fontSize: 10.0),
          ),
        ],
      ),
    );
  }

  ListTile _tile(
      String title,
      String subtitle,
      IconData icon,
      SolicitacaoMotorista amigo,
      ListaSolicitacoesMotoristaController _controller,
      bool isFinalizado,
      BuildContext _context) {
    subtitle = Utils.getDesStatusCorrida(amigo.indStatusCorrida);
    String subtitleaux = subtitle;
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
                  if (ApiBaseHelper.userSessao?.indBloqueado != null &&
                      ApiBaseHelper.userSessao?.indBloqueado == 1) {
                    LoginControler.showToast(_context,
                        "Usuário bloqueado não é possível aceitar corridas.");
                  } else {
                    if (ApiBaseHelper.userSessao?.indBloqueado != null &&
                        ApiBaseHelper.userSessao?.indBloqueado == 1) {
                      LoginControler.showToast(_context,
                          "Usuário bloqueado não é possível aceitar corridas.");
                    } else {
                      showAlertDialog(_context, amigo.numSeq!, _controller,
                          amigo.indStatusCorrida!, amigo);
                      //amigo.indStatusCorrida = Utils.getDesStatusProxStatusCorrida(amigo.indStatusCorrida);
                    }
                  }
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
      ListaSolicitacoesMotoristaController _controller,
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
        // Se for cancelamento, usa dialog com motivo obrigatório
        if (nextStatus == ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA) {
          Navigator.of(_context).pop(); // Fecha dialog atual
          
          final motivo = await CancelCorridaDialog.show(
            _context,
            corridaId: numSeqChamado.toString(),
            tituloCorrida: solicitacao.desEnderecoEntrega ?? 'Corrida #$numSeqChamado',
          );
          
          if (motivo != null && motivo.isNotEmpty) {
            _controller.finalizarChamado(
              numSeqChamado,
              nextStatus,
              motivoCancelamento: motivo,
            );
          } else {
            // Usuário fechou o diálogo sem confirmar — informa que não foi cancelado
            LoginControler.showToast(
              _context,
              'Cancelamento não realizado. Informe o motivo para cancelar.',
            );
          }
          return;
        }
        
        if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
            indStatusAtualCorrida) {
          bool sucess =
              await _controller.aceitarCorrida(numSeqChamado, nextStatus);
          if (sucess) {
            Navigator.of(_context).pop();
            if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                indStatusAtualCorrida) {
              Navigator.pushNamed(
                _context,
                AppRoutes.corridas,
                arguments: {
                  'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO,
                },
              );
            } else {
              _controller.finalizarChamado(numSeqChamado, nextStatus);
              Navigator.of(_context).pop();
            }
          }
        } else {
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
                currentUserType: 'motorista',
              );
            }
          }
        }
      },
    );

    // Para nova corrida: exibe ganho em destaque antes do aceite
    Widget dialogContent;
    if (indStatusAtualCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA) {
      final ganho = solicitacao.vlrTotalMotorista;
      final ganhoText = ganho != null && ganho > 0
          ? Utils.formatBRL(ganho)
          : 'Valor a calcular';
      final enderecoRetirada = solicitacao.enderecoEmpresa ?? 'Endereço não informado';
      final enderecoEntrega = solicitacao.desEnderecoEntrega != null
          ? '${solicitacao.desEnderecoEntrega}${solicitacao.desNumeroEndereco != null ? ', ${solicitacao.desNumeroEndereco}' : ''}'
          : 'Destino não informado';
      final distancia = solicitacao.qtdKmCorrida != null
          ? '${solicitacao.qtdKmCorrida!.toStringAsFixed(1)} km'
          : null;

      dialogContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ganho em destaque
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              children: [
                Text('Você receberá', style: TextStyle(fontSize: 13, color: Colors.green.shade700)),
                const SizedBox(height: 4),
                Text(
                  ganhoText,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                if (distancia != null)
                  Text(distancia, style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Rota
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.radio_button_checked, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(enderecoRetirada, style: const TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(enderecoEntrega, style: const TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 8),
          Text('Deseja aceitar esta corrida?', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ],
      );
    } else {
      dialogContent = Text("Deseja realmente ${text}?");
    }

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: indStatusAtualCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA
          ? const Text("Aceitar corrida?")
          : Text("Confirmar"),
      content: dialogContent,
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
