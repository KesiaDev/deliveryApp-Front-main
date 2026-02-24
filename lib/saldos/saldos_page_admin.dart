import 'dart:developer';

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/empresa/corridas/sol_nova_corrida_page.dart';
import 'package:delivery_front/home/home_empresa/home_page_empresa.dart';
import 'package:delivery_front/home/widgets/active_project_card.dart';
import 'package:delivery_front/home/widgets/task_column.dart';
import 'package:delivery_front/shared/components/filter/filterscreen.dart';
import 'package:delivery_front/shared/models/DadosCorrida.dart';
import 'package:delivery_front/shared/models/SaldosCorrida.dart';
import 'package:delivery_front/shared/models/consultaRequest.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:flash/flash.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';

class SaldosPageAdmin extends StatefulWidget {
  final Usuario? userInfo = ApiBaseHelper.userSessao;

  SaldosPageAdmin({Key? key, this.userConsulta, this.isAdm}) : super(key: key);

  final bool buscaChamados = false;
  final Usuario? userConsulta;
  final bool? isAdm;

  @override
  _SaldosPageAdmin createState() => _SaldosPageAdmin();
}

int currentTimeInSeconds() {
  var ms = (new DateTime.now()).millisecondsSinceEpoch;
  return (ms / 1000).round();
}

class _SaldosPageAdmin extends State<SaldosPageAdmin>
    with WidgetsBindingObserver {
  bool has = false;
  Usuario user = Usuario();
  int? timeStampInicial = 0;

  bool isAdm = false;

  ConsultaRequest? req = ConsultaRequest(
      dtaIni: ApiBaseHelper.findFirstDateOfTheWeek(DateTime.now()),
      dtaFim: ApiBaseHelper.findLastDateOfTheWeek(DateTime.now()));

  UserService _userService = new UserService();

  Text subheading(String title) {
    return Text(
      title,
      style: TextStyle(
          color: AppColors.grey,
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2),
    );
  }

  @override
  void initState() {
    if (widget.isAdm!)
      user = widget.userConsulta!;
    else
      user = widget.userInfo!;

    isAdm = widget.isAdm ?? false;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _createFooterItem(
      {required IconData icon,
      required String text,
      required GestureTapCallback onTap}) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Icon(icon),
          Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(text),
          )
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title:
            //(user.indTipo == 1 ? Obx(() => Text('${c.status}')) : Text("")),
            // (user.indTipo == 1 ? Obx(() => Text('${"ONLINE"}')) : Text("")),
            Text(
          (user.desNome ?? "") + " - Saldo ",
          style: TextStyle(color: Colors.white),
        ),

        /// backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.transparent,
        leading: Builder(
          builder: (BuildContext context) {
            return Container(
              margin: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.transparent),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.red,
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
            );
          },
        ),
      ),
      body: montaTelaInicialEmpresa(width),
      floatingActionButton: FloatingActionButton(
        heroTag: "buscaButtonFilterScreen",
        shape: CircleBorder(
          side: BorderSide(
            color: Colors.black,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.search),
        ),
        backgroundColor: Colors.black87,
        onPressed: () async {
          //getCurrentLocation();
          // var location = await _locationTracker.getLocation();
          // await _userService.novoPedidoDeSocorro(
          //     location.latitude!, location.longitude!);
          var result =
              await Navigator.push(context, MaterialPageRoute(builder: (ctx) {
            return FilterScreen();
          }));

          setState(() {
            log("Filter values selected in Previous Screen\n ${result}");
            if (result != null) req = ConsultaRequest.fromJson(result);
          });
          print(result);
        },
      ),
    );
  }

  FutureBuilder criaInfoDia({int? codMotorista, int? codEmpresa}) {
    int? codEmAux;
    int? codMotAux;

    var userNew = widget.userInfo;

    if (ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA == user.indTipo) {
      codMotAux == userNew!.usuarioResp!.motoristas!.first.codMotorista;
    }

    if (ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA == user.indTipo) {
      codEmAux == userNew!.usuarioResp!.empresas!.first.codEmpresa;
    }

    return FutureBuilder<List<SaldosCorrida>>(
      future: _userService.buscaDadosSaldosCorrida(
          codEmpresa: codEmAux,
          codMotorista: codMotAux,
          dtaIni: ApiBaseHelper.findFirstDateOfTheMonth(DateTime.now()),
          dtaFim: ApiBaseHelper.lastDayOfMonth(DateTime.now())),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // while data is loading:
          if (snapshot.connectionState.name == "done") {
            return Container(
                child: Column(
              children: <Widget>[
                SizedBox(height: 15.0),
                TaskColumn(
                  icon: Icons.motorcycle,
                  title: 'Total de corridas',
                  subtitle: 'Nenhuma informação encontrada',
                ),
                SizedBox(
                  height: 15.0,
                ),
              ],
            ));
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        } else {
          // data loaded:
          final List<SaldosCorrida>? list = snapshot.data;

          if (list != null) {
            SaldosCorrida corridasCanc = SaldosCorrida();
            SaldosCorrida corridasAceita = SaldosCorrida();
            SaldosCorrida CorridasPagas = SaldosCorrida();
            SaldosCorrida corridasApagar = SaldosCorrida();
            SaldosCorrida corridasFinalizadas = SaldosCorrida();

            for (var element in list) {
              //Não pago
              if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                  element.indStatusPagamentoEstabelecimento) {
                corridasApagar = element;
              }

//Pago
              if (ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ==
                  element.indStatusPagamentoEstabelecimento) {
                CorridasPagas = element;
              }
            }

            if (userNew!.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
              return Container(
                  child: Column(
                children: <Widget>[
                  SizedBox(height: 15.0),
                  TaskColumn(
                    icon: Icons.motorcycle,
                    title: 'Valor total de corridas',
                    subtitle:
                        'R\$ ${corridasApagar.vlrTotal ?? 0} a receber. R\$ ${CorridasPagas.vlrTotal ?? 0} já pago',
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  TaskColumn(
                    icon: Icons.place,
                    title: 'A receber',
                    subtitle: 'R\$ ${corridasApagar.vlrTotal ?? 0}',
                  ),
                  SizedBox(height: 15.0),
                  TaskColumn(
                    icon: Icons.check_circle_outline,
                    title: 'Recebido',
                    subtitle: 'R\$ ${CorridasPagas.vlrTotal ?? 0}',
                  )
                ],
              ));
            } else {
              return Container(
                  child: Column(
                children: <Widget>[
                  SizedBox(height: 15.0),
                  TaskColumn(
                    icon: Icons.motorcycle,
                    title: 'Valor total de corridas',
                    subtitle:
                        'R\$ ${corridasApagar.vlrTotalRestaurante ?? 0} a pagar. R\$ ${CorridasPagas.vlrTotalRestaurante ?? 0} em andamento',
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  TaskColumn(
                    icon: Icons.place,
                    title: 'A pagar',
                    subtitle: 'R\$ ${corridasApagar.vlrTotalRestaurante ?? 0}',
                  ),
                  SizedBox(height: 15.0),
                  TaskColumn(
                    icon: Icons.check_circle_outline,
                    title: 'Pago',
                    subtitle: 'R\$ ${CorridasPagas.vlrTotalRestaurante ?? 0}',
                  )
                ],
              ));
            }
          } else {
            return Container(
                child: Column(
              children: <Widget>[
                SizedBox(height: 15.0),
                TaskColumn(
                  icon: Icons.motorcycle,
                  title: 'Total de corridas',
                  subtitle: 'Nenhuma informação encontrada',
                ),
                SizedBox(
                  height: 15.0,
                ),
              ],
            ));
          }
        }
      },
    );
  }

  FutureBuilder criaInfoMes({int? codMotorista, int? codEmpresa}) {
    int? codEmAux;
    int? codMotAux;

    var userNew = ApiBaseHelper.userSessao;

    if (ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA == user.indTipo) {
      codMotAux == userNew!.usuarioResp!.motoristas!.first.codMotorista;
    }

    if (ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA == user.indTipo) {
      codEmAux == userNew!.usuarioResp!.empresas!.first.codEmpresa;
    }

    return FutureBuilder<List<SaldosCorrida>>(
      future: _userService.buscaDadosSaldosCorrida(
          codEmpresa: codEmAux,
          codMotorista: codMotAux,
          dtaIni: ApiBaseHelper.findFirstDateOfTheMonth(DateTime.now()),
          dtaFim: ApiBaseHelper.lastDayOfMonth(DateTime.now())),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasData) {
          // while data is loading:
          final List<SaldosCorrida>? list = snapshot.data;
          var totalCorridas = 0;
          if (list != null) {
            SaldosCorrida corridasCanc = SaldosCorrida();
            SaldosCorrida corridasAceita = SaldosCorrida();
            SaldosCorrida corridasEmAndamento = SaldosCorrida();
            SaldosCorrida corridasNovas = SaldosCorrida();
            SaldosCorrida corridasFinalizadas = SaldosCorrida();

            for (var element in list) {
              if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                  element.indStatusPagamentoEstabelecimento) {
                corridasNovas = element;
                // totalCorridas =
                //  (corridasNovas.qtdCorridas ?? 0) + totalCorridas;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ==
                  element.indStatusPagamentoEstabelecimento) {
                corridasAceita = element;
                //    totalCorridas =
                //   (corridasNovas.qtdCorridas ?? 0) + totalCorridas;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO ==
                  element.indStatusPagamentoEstabelecimento) {
                corridasEmAndamento = element;
                //  totalCorridas =
                //   (corridasNovas.qtdCorridas ?? 0) + totalCorridas;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA ==
                  element.indStatusPagamentoEstabelecimento) {
                corridasFinalizadas = element;
                //totalCorridas =
                //  (corridasNovas.qtdCorridas ?? 0) + totalCorridas;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA ==
                  element.indStatusPagamentoEstabelecimento) {
                corridasCanc = element;
                // totalCorridas =
                //   (corridasNovas.qtdCorridas ?? 0) + totalCorridas;
              }
            }

            double percentCorridasConcluidas =
                ((corridasFinalizadas.vlrTotal ?? 1) / totalCorridas);

            double percentCorridasCanc = 0;
            if (corridasCanc.indStatusPagamentoEstabelecimento != null &&
                corridasCanc.indStatusPagamentoEstabelecimento! > 0)
              percentCorridasCanc =
                  ((corridasCanc.indStatusPagamentoEstabelecimento ?? 1) /
                      totalCorridas);

            return Container(
                child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    ActiveProjectsCard(
                      cardColor: AppColors.black,
                      loadingPercent: 1.0,
                      title: 'Corridas solicitadas',
                      subtitle: '${totalCorridas}',
                    ),
                    SizedBox(width: 20.0),
                    ActiveProjectsCard(
                      cardColor: AppColors.black,
                      loadingPercent: percentCorridasConcluidas,
                      title: 'Corridas concluídas',
                      subtitle:
                          '${corridasFinalizadas.indStatusPagamentoEstabelecimento}',
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    ActiveProjectsCard(
                      cardColor: AppColors.black,
                      loadingPercent: percentCorridasCanc,
                      title: 'Canceladas',
                      subtitle:
                          '${corridasCanc.indStatusPagamentoEstabelecimento ?? 0}',
                    ),
                    SizedBox(width: 20.0),
                    // ActiveProjectsCard(
                    //   cardColor: AppColors.black,
                    //   loadingPercent: 0.9,
                    //   title: 'Online Flutter Course',
                    //   subtitle: 'R\$ 23 - Total em corridas',
                    // ),
                  ],
                ),
              ],
            ));
          } else {
            return Container(
                child: Column(
              children: <Widget>[
                SizedBox(height: 15.0),
                TaskColumn(
                  icon: Icons.motorcycle,
                  title: 'Total de corridas',
                  subtitle: 'Nenhuma informação encontrada',
                ),
                SizedBox(
                  height: 15.0,
                ),
              ],
            ));
          }
        } else {
          if (snapshot.connectionState.name == "done") {
            // return Container(
            //     child: Column(
            //   children: <Widget>[
            //     SizedBox(height: 15.0),
            //     TaskColumn(
            //       icon: Icons.motorcycle,
            //       title: 'Total de corridas',
            //       subtitle: 'Nenhuma informação encontrada',
            //     ),
            //     SizedBox(
            //       height: 15.0,
            //     ),
            //   ],
            // ));
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          // data loaded:
        }

        return CircularProgressIndicator();
      },
    );
  }

  SafeArea montaTelaInicialEmpresa(double width) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Container(
                    color: Colors.transparent,
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            subheading('Informações gerais'),
                            if (user.indTipo ==
                                ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA)
                              GestureDetector(
                                onTap: () async {
                                  if (user.usuarioResp!.indBloqueado == 1) {
                                    context.showInfoBar(
                                      duration: Duration(seconds: 8),
                                      content: Text(
                                          "Não será possível iniciar corrida, novas solicitações estão bloqueadas."),
                                    );
                                  } else {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              SolNovaCorridaPage()),
                                    );

                                    if (!mounted) return;
                                    setState(() {});
                                  }
                                },
                                child: Visibility(
                                    visible: isAdm ? false : true,
                                    child: HomePageEmpresa.calendarIcon()),
                              ),
                          ],
                        ),
                        criaInfoDia(codEmpresa: 1, codMotorista: 1),
                      ],
                    ),
                  ),
                  // Container(
                  //   color: Colors.transparent,
                  //   padding:
                  //       EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: <Widget>[
                  //       subheading('Números do mês'),
                  //       criaInfoMes(codEmpresa: 1, codMotorista: 1),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancelar"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Confirmar"),
      onPressed: () async {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Fecha o dialog primeiro
        await _userService.logoffLocalDB();
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.splash,
          (Route<dynamic> route) => false,
        );
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Confirmar"),
      content: Text("Deseja realmente sair?"),
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

  void _showToast(BuildContext context, String text) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(text),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }
}

class Utils {
  static String mapStyles = '''[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]''';
}
