import 'package:flutter/material.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/motorista/corridas/lista_solicitacoes_motorista_controller.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'theme_components.dart';
import 'corrida_card.dart';
import 'empty_state.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({Key? key}) : super(key: key);

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  late ListaSolicitacoesMotoristaController _controller;
  List<SolicitacaoMotorista> _corridas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = ListaSolicitacoesMotoristaController(context);
    _loadCorridas();
  }

  Future<void> _loadCorridas() async {
    setState(() => _isLoading = true);
    try {
      final result = await _controller.buscaListaSolicitacoes(
        indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA,
      );
      setState(() {
        _corridas = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: const AppAppBar(title: "Histórico", showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadCorridas,
                  child: _corridas.isEmpty
                      ? const EmptyState(
                          title: "Nenhuma corrida concluída",
                          subtitle: "Suas corridas finalizadas aparecerão aqui",
                          icon: Icons.history,
                        )
                      : ListView.separated(
                          itemCount: _corridas.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final solicitacao = _corridas[index];
                            final empresa = solicitacao.dbEmpresasByCodEmpresa?.desNomeFantasia ?? "Empresa";
                            final distancia = "${solicitacao.qtdKmCorrida ?? 0} km";
                            final valor = "R\$ ${solicitacao.vlrTotalMotorista?.toStringAsFixed(2) ?? "0.00"}";
                            final data = ApiBaseHelper.getDtaFormatada(solicitacao.dthSolicitacao);

                            return CorridaCard(
                              title: "$empresa - $data",
                              distance: distancia,
                              value: valor,
                              status: "Concluída",
                              statusColor: Colors.green,
                              showAction: false,
                              onPrimaryAction: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.infoCorrida,
                                  arguments: solicitacao,
                                );
                              },
                            );
                          },
                        ),
                ),
        ),
      ),
    );
  }
}
