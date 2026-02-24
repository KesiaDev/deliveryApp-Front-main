import 'dart:developer';

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/home/widgets/maps/mapsSheet.dart';
import 'package:delivery_front/login/login_controller.dart';
import 'package:delivery_front/motorista/corridas/lista_solicitacoes_motorista_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = ListaSolicitacoesMotoristaController(context);
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
        appBar: AppBar(
          title: Text(ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                  widget.indTipoDefault
              ? 'Novas corridas'
              : ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO ==
                      widget.indTipoDefault
                  ? 'Minhas corridas - já iniciadas'
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

class ListaCemMotoristaView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FutureBuilder<List<SolicitacaoMotorista>>(
      future: controller.buscaListaSolicitacoes(
          indBuscaChamadosRaio: indStatusDefault ?? -1, isAdm: isAdm),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasData) {
          List<SolicitacaoMotorista> data = snapshot.data!;
          final route = ModalRoute.of(context);
          final pageName = route?.settings.name ?? "";
          log(pageName);
          return _jobsListView(data, controller);
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return CircularProgressIndicator();
      },
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

      if (amigo.desEnderecoEntrega != null)
        subtitleEndere = subtitleEndere + amigo.desEnderecoEntrega! + " - ";
      //+            amigo.desNumeroEndereco!;

      if (amigo.desObsCorrida != null)
        subtitleObsEntrega = subtitleObsEntrega + amigo.desObsCorrida!;
    }

    if (amigo.indTipoCorrida != null) {
      subtitleObsEntrega = subtitleObsEntrega +
          " - " +
          getTitleTipoCorrida(amigo.indTipoCorrida!);
    }

    subtitleObsEntrega =
        subtitleObsEntrega + ' - R\$ ${amigo.vlrTotalMotorista ?? 0}';

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
      Widget custom3) {
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
