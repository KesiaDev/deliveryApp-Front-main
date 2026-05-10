import 'dart:developer';

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/empresa/corridas/sol_nova_corrida_page.dart';
import 'package:delivery_front/home/home_empresa/home_page_empresa.dart';
import 'package:delivery_front/home/widgets/active_project_card.dart';
import 'package:delivery_front/home/widgets/task_column.dart';
import 'package:delivery_front/shared/components/filter/filterscreen.dart';
import 'package:delivery_front/shared/models/SaldosCorrida.dart';
import 'package:delivery_front/shared/models/consultaRequest.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaldosPage extends StatefulWidget {
  final Usuario? userInfo = ApiBaseHelper.userSessao;

  SaldosPage({
    Key? key,
    bool? buscaChamados,
    Usuario? userInfo,
    bool? isAdm,
  }) : super(key: key);

  SaldosPage.second({Key? key, this.userConsulta, this.isAdm})
      : super(key: key);

  bool buscaChamados = false;
  Usuario? userConsulta;
  bool? isAdm;

  @override
  _SaldosPage createState() => _SaldosPage();
}

int currentTimeInSeconds() {
  var ms = (new DateTime.now()).millisecondsSinceEpoch;
  return (ms / 1000).round();
}

class _SaldosPage extends State<SaldosPage> with WidgetsBindingObserver {
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
    if (widget.isAdm != null && widget.isAdm!)
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
        title: Text(
          (user.desNome ?? "Empresa") + " - Saldo",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          maxLines: 1,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ),
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
      body: montaTelaInicialEmpresa(width),
      floatingActionButton: null,
    );
  }

  FutureBuilder criaInfoDia({int? codMotorista, int? codEmpresa}) {
    int? codEmAux;
    int? codMotAux;

    var userNew = user;

    if (ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA == user.indTipo) {
      final motoristas = userNew.usuarioResp?.motoristas;
      if (motoristas != null && motoristas.isNotEmpty) {
        codMotAux = motoristas.first.codMotorista;
      }
    }

    if (ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA == user.indTipo) {
      final empresas = userNew.usuarioResp?.empresas;
      if (empresas != null && empresas.isNotEmpty) {
        codEmAux = empresas.first.codEmpresa;
      }
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
                  icon: Icons.motorcycle_rounded,
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
            SaldosCorrida corridasPagas = SaldosCorrida();
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
                corridasPagas = element;
              }
            }

            if (userNew.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
              return Container(
                  child: Column(
                children: <Widget>[
                  SizedBox(height: 15.0),
                TaskColumn(
                  icon: Icons.motorcycle_rounded,
                  title: 'Valor total de corridas',
                  subtitle:
                      'R\$ ${(corridasApagar.vlrTotal?.toDouble() ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')} a receber. R\$ ${(corridasPagas.vlrTotal?.toDouble() ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')} já pago',
                ),
                  SizedBox(
                    height: 15.0,
                  ),
                  TaskColumn(
                    icon: Icons.place,
                    title: 'A receber',
                    subtitle: 'R\$ ${(corridasApagar.vlrTotal?.toDouble() ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')}',
                  ),
                  SizedBox(height: 15.0),
                  TaskColumn(
                    icon: Icons.check_circle_outline,
                    title: 'Recebido',
                    subtitle: 'R\$ ${(corridasPagas.vlrTotal?.toDouble() ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')}',
                  ),
                  Visibility(
                    visible: ApiBaseHelper.userSessao!.indTipo ==
                            ApiBaseHelper.IND_TIP_PERFIL_99_ADMIN_SISTEMA
                        ? true
                        : false,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (corridasApagar != null &&
                              (corridasApagar.vlrTotal != null &&
                                  corridasApagar.vlrTotal! > 0)) {
                            showAlertDialogPagamento(context, corridasApagar, 1);
                          } else {
                            _showToast(context, "Nenhum valor a ser pago");
                          }
                        },
                        icon: Icon(
                          Icons.attach_money_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          "Realizar pagamento",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ));
            } else {
              return Container(
                  child: Column(
                children: <Widget>[
                  SizedBox(height: 15.0),
                  TaskColumn(
                    icon: Icons.motorcycle_rounded,
                    title: 'Valor total de corridas',
                    subtitle:
                        'R\$ ${(corridasApagar.vlrTotalRestaurante?.toDouble() ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')} a pagar. R\$ ${(corridasPagas.vlrTotalRestaurante?.toDouble() ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')} em andamento',
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  TaskColumn(
                    icon: Icons.place,
                    title: 'A pagar',
                    subtitle: 'R\$ ${(corridasApagar.vlrTotalRestaurante?.toDouble() ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')}',
                  ),
                  SizedBox(height: 15.0),
                  TaskColumn(
                    icon: Icons.check_circle_outline,
                    title: 'Pago',
                    subtitle: 'R\$ ${(corridasPagas.vlrTotalRestaurante?.toDouble() ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')}',
                  ),
                  Visibility(
                    visible: ApiBaseHelper.userSessao!.indTipo ==
                            ApiBaseHelper.IND_TIP_PERFIL_99_ADMIN_SISTEMA
                        ? true
                        : false,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (corridasApagar != null &&
                              (corridasApagar.vlrTotalRestaurante != null &&
                                  corridasApagar.vlrTotalRestaurante! > 0)) {
                            showAlertDialogPagamento(context, corridasApagar, 2);
                          } else {
                            _showToast(context, "Nenhum valor a ser pago");
                          }
                        },
                        icon: Icon(
                          Icons.attach_money_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          "Recebimento de pagamento",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ));
            }
          } else {
            return Container(
                child: Column(
              children: <Widget>[
                SizedBox(height: 15.0),
                TaskColumn(
                  icon: Icons.motorcycle_rounded,
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

  showAlertDialogPagamento(
      BuildContext _context, SaldosCorrida saldo, int indTipo) {
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
        if (indTipo != null && indTipo == 2) {
          await _userService.realizaRecebimentoEstabelecimento(
              saldo.corridaList ?? "",
              widget.userConsulta!.usuarioResp!.empresas!.first.codEmpresa ??
                  -1);
        } else {
          await _userService.realizaPagamentoMotorista(
              saldo.corridaList ?? "",
              widget.userConsulta!.usuarioResp!.motoristas!.first
                      .codMotorista ??
                  -1);
        }
        Navigator.of(_context).pop();
        setState(() {});
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Confirmar"),
      content: Text("Deseja realmente cancelar?"),
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

  FutureBuilder criaInfoMes({int? codMotorista, int? codEmpresa}) {
    int? codEmAux;
    int? codMotAux;

    var userNew = ApiBaseHelper.userSessao;

    if (ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA == user.indTipo) {
      codMotAux = userNew!.usuarioResp!.motoristas!.first.codMotorista;
    }

    if (ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA == user.indTipo) {
      codEmAux = userNew!.usuarioResp!.empresas!.first.codEmpresa;
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
                      cardColor: Color(0xFFFFFFFF),
                      loadingPercent: 1.0,
                      title: 'Corridas solicitadas',
                      subtitle: '${totalCorridas}',
                    ),
                    SizedBox(width: 20.0),
                    ActiveProjectsCard(
                      cardColor: Color(0xFFFFFFFF),
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
                      cardColor: Color(0xFFFFFFFF),
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
                  icon: Icons.motorcycle_rounded,
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
