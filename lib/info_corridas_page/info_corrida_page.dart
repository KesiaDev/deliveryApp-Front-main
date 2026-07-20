import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/empresa/corridas/sol_nova_corrida_page.dart';
import 'package:delivery_front/home/widgets/task_column.dart';
import 'package:delivery_front/modules/payments/screens/carteira_fool_screen.dart';
import 'package:delivery_front/modules/payments/services/empresa_payment_service.dart';
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
  void initState() {
    super.initState();
  }

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
      codMotAux = (userNew?.usuarioResp?.motoristas?.isNotEmpty == true)
          ? userNew!.usuarioResp!.motoristas!.first.codMotorista
          : null;
    }

    if (ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA == user.indTipo) {
      codEmAux = (userNew?.usuarioResp?.empresas?.isNotEmpty == true)
          ? userNew!.usuarioResp!.empresas!.first.codEmpresa
          : null;
    }

    return FutureBuilder<List<DadosCorridas>>(
      future: _userService.buscaDadosCorrida(
          codEmpresa: codEmAux,
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
      codMotAux = (userNew?.usuarioResp?.motoristas?.isNotEmpty == true)
          ? userNew!.usuarioResp!.motoristas!.first.codMotorista
          : null;
    }

    if (ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA == user.indTipo) {
      codEmAux = (userNew?.usuarioResp?.empresas?.isNotEmpty == true)
          ? userNew!.usuarioResp!.empresas!.first.codEmpresa
          : null;
    }

    return FutureBuilder<List<DadosCorridas>>(
      future: _userService.buscaDadosCorrida(
          codEmpresa: codEmAux,
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

  void _irNovaCorrida() {
    if (widget.userInfo.usuarioResp?.indBloqueado == 1) {
      context.showInfoBar(
        duration: const Duration(seconds: 8),
        content: const Text("Novas solicitações estão bloqueadas."),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SolNovaCorridaPage()),
    ).then((_) { if (mounted) setState(() {}); });
  }

  void _irAgendarCorrida() {
    if (widget.userInfo.usuarioResp?.indBloqueado == 1) {
      context.showInfoBar(
        duration: const Duration(seconds: 8),
        content: const Text("Novas solicitações estão bloqueadas."),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SolNovaCorridaPage()),
    ).then((_) { if (mounted) setState(() {}); });
  }

  SafeArea montaTelaInicialEmpresa(double width) {
    const Color backgroundLight = Color(0xFFF8F6FB);

    final emp = widget.userInfo.usuarioResp?.empresas?.isNotEmpty == true
        ? widget.userInfo.usuarioResp!.empresas!.first
        : null;
    final codEmpresa = emp?.codEmpresa;

    return SafeArea(
      child: Container(
        color: backgroundLight,
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[

                    // ── Botão NOVA CORRIDA (grande) ───────────────────
                    if (!isAdm)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _irNovaCorrida,
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE53935).withOpacity(0.40),
                                    blurRadius: 16,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.20),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: const Icon(Icons.motorcycle_rounded,
                                          color: Colors.white, size: 44),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Nova Corrida',
                                              style: GoogleFonts.poppins(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              )),
                                          Text('Solicitar motoboy agora',
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                color: Colors.white.withOpacity(0.85),
                                              )),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        color: Colors.white, size: 22),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ── Botão AGENDAR CORRIDA ─────────────────────────
                    if (!isAdm)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _irAgendarCorrida,
                            child: Ink(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3949AB),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3949AB).withOpacity(0.28),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                child: Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded,
                                        color: Colors.white, size: 30),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Agendar Corrida',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              )),
                                          Text('Solicitar para um horário específico',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.white.withOpacity(0.85),
                                              )),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        color: Colors.white, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ── Card CARTEIRA FOOL ────────────────────────────
                    if (!isAdm && codEmpresa != null)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CarteiraFoolScreen(
                              codEmpresa: codEmpresa,
                              empresaName: widget.userInfo.desNome ?? 'Empresa',
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF43A047).withOpacity(0.30),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_rounded,
                                  color: Colors.white, size: 28),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Carteira Fool',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.85),
                                        )),
                                    StreamBuilder<double>(
                                      stream: EmpresaPaymentService.streamWalletBalance(codEmpresa),
                                      builder: (_, snap) {
                                        final bal = snap.data ?? 0.0;
                                        return Text(
                                          'R\$ ${bal.toStringAsFixed(2).replaceAll('.', ',')}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text('Recarregar',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Informações gerais - Diário ───────────────────
                    Container(
                      color: backgroundLight,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          subheading('Informações gerais - Diário'),
                          criaInfoDia(codEmpresa: 1, codMotorista: 1),
                        ],
                      ),
                    ),

                    // ── Números do mês ────────────────────────────────
                    Container(
                      color: backgroundLight,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          subheading('Números do mês'),
                          const SizedBox(height: 8.0),
                          criaInfoMes(codEmpresa: 1, codMotorista: 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
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
