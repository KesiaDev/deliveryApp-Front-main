import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/empresa/corridas/sol_nova_corrida_page.dart';
import 'package:delivery_front/home/home_empresa/home_page_empresa.dart';
import 'package:delivery_front/home/widgets/active_project_card.dart';
import 'package:delivery_front/home/widgets/task_column.dart';
import 'package:delivery_front/shared/models/DadosCorrida.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoCorridaPage extends StatefulWidget {
  final Usuario userInfo;
  final bool? isAdm;

  const InfoCorridaPage({Key? key, required this.userInfo, this.isAdm})
      : super(key: key);
  const InfoCorridaPage.second({Key? key, required this.userInfo, this.isAdm})
      : super(key: key);

  @override
  _InfoCorridaPageState createState() => _InfoCorridaPageState();
}

class _InfoCorridaPageState extends State<InfoCorridaPage>
    with WidgetsBindingObserver {
  @override
  void initState() {}

  late Usuario user;
  UserService _userService = new UserService();
  bool isAdm = false;

  @override
  Widget build(BuildContext context) {
    user = widget.userInfo;
    double width = MediaQuery.of(context).size.width;
    isAdm = widget.isAdm ?? false;
    return montaTelaInicialEmpresa(width);
  }

  FutureBuilder criaInfoDia({int? codMotorista, int? codEmpresa}) {
    int? codEmAux;
    int? codMotAux;

    var userNew = ApiBaseHelper.userSessao;

    if (ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA == user.indTipo) {
      codMotAux == userNew!.usuarioResp!.motoristas!.first.codMotorista;
    }

    if (ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA == user.indTipo) {
      codEmAux == userNew!.usuarioResp!.empresas!.first.codEmpresa;
    }

    return FutureBuilder<List<DadosCorridas>>(
      future: _userService.buscaDadosCorrida(
          codEmpresa: ((widget.isAdm != null && widget.isAdm!)
              ? codEmAux
              : user.usuarioResp?.empresas!.first.codEmpresa),
          codMotorista: codMotAux,
          dtaIni: DateTime.now(),
          dtaFim: DateTime.now(),
          isAdm: widget.isAdm),
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
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            );
          }
        } else {
          // data loaded:
          final List<DadosCorridas>? list = snapshot.data;
          var isAdm = widget.isAdm;
          if (list != null) {
            DadosCorridas corridasCanc = DadosCorridas();
            DadosCorridas corridasAceita = DadosCorridas();
            DadosCorridas corridasEmAndamento = DadosCorridas();
            DadosCorridas corridasNovas = DadosCorridas();
            DadosCorridas corridasFinalizadas = DadosCorridas();
            var totalMotoristasOnline = 0;
            for (var element in list) {
              if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                  element.indStatusCorrida) {
                corridasNovas = element;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ==
                  element.indStatusCorrida) {
                corridasAceita = element;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO ==
                  element.indStatusCorrida) {
                corridasEmAndamento = element;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA ==
                  element.indStatusCorrida) {
                corridasFinalizadas = element;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA ==
                  element.indStatusCorrida) {
                corridasCanc = element;
              }

              if (element.totalMotoristasOnline != null) {
                totalMotoristasOnline = (element.totalMotoristasOnline ?? 0) +
                    totalMotoristasOnline;
              }
            }

            return Container(
                child: Column(
              children: <Widget>[
                // Grid de 2 colunas para os cards
                Row(
                  children: [
                    Expanded(
                      child: TaskColumn(
                        icon: Icons.motorcycle,
                        title: 'Total de corridas',
                        subtitle:
                            '${corridasNovas.qtdCorridas ?? 0} na fila para aceite. ${corridasEmAndamento.qtdCorridas ?? 0} em andamento',
                      ),
                    ),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: TaskColumn(
                        icon: Icons.motorcycle,
                        title: 'Corridas em andamento',
                        subtitle: '${corridasEmAndamento.qtdCorridas ?? 0}',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.0),
                Row(
                  children: [
                    Expanded(
                      child: TaskColumn(
                        icon: Icons.check_circle_rounded,
                        title: 'Corridas concluídas',
                        subtitle: '${corridasFinalizadas.qtdCorridas ?? 0}',
                      ),
                    ),
                    SizedBox(width: 12.0),
                    Visibility(
                      visible: isAdm ?? false,
                      child: Expanded(
                        child: TaskColumn(
                          icon: Icons.person_outline,
                          title: 'Motoristas Online',
                          subtitle: '$totalMotoristasOnline',
                        ),
                      ),
                    ),
                    if (isAdm == false) Expanded(child: SizedBox()),
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
        }
      },
    );
    setState(() {});
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

    return FutureBuilder<List<DadosCorridas>>(
      future: _userService.buscaDadosCorrida(
          codEmpresa: (widget.isAdm != null && widget.isAdm!
              ? codEmAux
              : user.usuarioResp?.empresas!.first.codEmpresa),
          codMotorista: codMotAux,
          dtaIni: ApiBaseHelper.findFirstDateOfTheMonth(DateTime.now()),
          dtaFim: ApiBaseHelper.lastDayOfMonth(DateTime.now()),
          isAdm: widget.isAdm),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // while data is loading:
          final List<DadosCorridas>? list = snapshot.data;
          var totalCorridas = 0;
          var totalMotoristasOnline = 0;
          if (list != null) {
            DadosCorridas corridasCanc = DadosCorridas();
            DadosCorridas corridasAceita = DadosCorridas();
            DadosCorridas corridasEmAndamento = DadosCorridas();
            DadosCorridas corridasNovas = DadosCorridas();
            DadosCorridas corridasFinalizadas = DadosCorridas();

            for (var element in list) {
              if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                  element.indStatusCorrida) {
                corridasNovas = element;
                totalCorridas =
                    (corridasNovas.qtdCorridas ?? 0) + totalCorridas;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ==
                  element.indStatusCorrida) {
                corridasAceita = element;
                totalCorridas =
                    (corridasAceita.qtdCorridas ?? 0) + totalCorridas;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO ==
                  element.indStatusCorrida) {
                corridasEmAndamento = element;
                totalCorridas =
                    (corridasEmAndamento.qtdCorridas ?? 0) + totalCorridas;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA ==
                  element.indStatusCorrida) {
                corridasFinalizadas = element;
                totalCorridas =
                    (corridasFinalizadas.qtdCorridas ?? 0) + totalCorridas;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA ==
                  element.indStatusCorrida) {
                corridasCanc = element;
                totalCorridas = (corridasCanc.qtdCorridas ?? 0) + totalCorridas;
              }

              if (element.totalMotoristasOnline != null) {
                totalMotoristasOnline = (element.totalMotoristasOnline ?? 0) +
                    totalMotoristasOnline;
              }
            }

            double percentCorridasConcluidas = 0.0;
            if (totalCorridas != null && totalCorridas > 0) {
              percentCorridasConcluidas = (corridasFinalizadas.qtdCorridas ?? 0) /
                  (totalCorridas == 0 ? 1 : totalCorridas);
            }

            double percentCorridasCanceladas = 0.0;
            if (corridasCanc.qtdCorridas != null &&
                corridasCanc.qtdCorridas! > 0 && totalCorridas > 0) {
              percentCorridasCanceladas = (corridasCanc.qtdCorridas ?? 0) /
                  (totalCorridas == 0 ? 1 : totalCorridas);
            }

            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 0.80,
              children: [
                _indicadorCircular(
                  titulo: 'Corridas solicitadas',
                  valor: totalCorridas.toString(),
                  porcentagem: 1.0,
                  cor: Colors.red,
                ),
                _indicadorCircular(
                  titulo: 'Corridas concluídas',
                  valor: '${(percentCorridasConcluidas * 100).toStringAsFixed(1)}%',
                  porcentagem: percentCorridasConcluidas,
                  cor: Colors.green,
                ),
                _indicadorCircular(
                  titulo: 'Canceladas',
                  valor: '${(percentCorridasCanceladas * 100).toStringAsFixed(1)}%',
                  porcentagem: percentCorridasCanceladas,
                  cor: Colors.grey,
                ),
              ],
            );
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
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            );
          }

          // data loaded:
        }

        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
          ),
        );
      },
    );
  }

  Widget subheading(String title) {
    // Cores do padrão FOLL
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color iconColor = Color(0xFF9E9E9E);
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, color: iconColor, size: 20),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: textPrimary,
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Widget indicador circular padronizado
  Widget _indicadorCircular({
    required String titulo,
    required String valor,
    required double porcentagem,
    required Color cor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 90,
            width: 90,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: porcentagem > 1.0 ? 1.0 : porcentagem,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(cor),
                ),
                Center(
                  child: Text(
                    valor,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              height: 1.1,
            ),
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  SafeArea montaTelaInicialEmpresa(double width) {
    // Cores do padrão FOLL
    const Color backgroundColor = Color(0xFFFFFFFF);
    const Color backgroundLight = Color(0xFFF8F6FB);
    
    return SafeArea(
      child: Container(
        color: backgroundLight,
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Container(
                      color: backgroundLight,
                      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Flexible(
                                child: subheading('Informações gerais - Diário'),
                              ),
                              if (!isAdm)
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      if (widget.userInfo.usuarioResp!.indBloqueado == 1) {
                                        context.showInfoBar(
                                          duration: Duration(seconds: 8),
                                          content: Text(
                                              "Não será possível iniciar corrida, novas solicitações estão bloqueadas."),
                                        );
                                      } else {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => SolNovaCorridaPage()),
                                        );
                                        if (!mounted) return;
                                        setState(() {});
                                      }
                                    },
                                    icon: Icon(Icons.add, size: 18, color: Colors.red),
                                    label: Text(
                                      'Nova corrida',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8.0),
                          criaInfoDia(codEmpresa: 1, codMotorista: 1),
                        ],
                      ),
                    ),
                    Container(
                      color: backgroundLight,
                      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          subheading('Números do mês'),
                          SizedBox(height: 8.0),
                          criaInfoMes(codEmpresa: 1, codMotorista: 1),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
