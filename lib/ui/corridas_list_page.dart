import 'package:flutter/material.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/motorista/corridas/lista_solicitacoes_motorista_controller.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/shared/components/Utils.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/modules/chat/services/chat_automatic_messages.dart';
import 'package:delivery_front/shared/dialogs/cancel_corrida_dialog.dart';
import 'theme_components.dart';
import 'corrida_card.dart';
import 'app_drawer.dart';
import 'filters_page.dart';
import 'empty_state.dart';

class CorridasListPage extends StatefulWidget {
  final int? indTipoDefault;

  const CorridasListPage({Key? key, this.indTipoDefault}) : super(key: key);

  @override
  State<CorridasListPage> createState() => _CorridasListPageState();
}

class _CorridasListPageState extends State<CorridasListPage> {
  late ListaSolicitacoesMotoristaController _controller;
  List<SolicitacaoMotorista> _corridas = [];
  bool _isLoading = true;
  DateTimeRange? _selectedRange;
  Set<String> _selectedTypes = {};

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
        indBuscaChamadosRaio: widget.indTipoDefault ?? -1,
      );
      setState(() {
        _corridas = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String get _appBarTitle {
    if (widget.indTipoDefault == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA) {
      return 'Novas corridas';
    } else if (widget.indTipoDefault == ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO) {
      return 'Corridas em andamento';
    } else if (widget.indTipoDefault == ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA) {
      return 'Histórico';
    }
    return 'Corridas';
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiBaseHelper.userSessao;
    final userService = UserService();

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppAppBar(
        title: _appBarTitle,
        showBack: false,
      ),
      drawer: AppDrawer(
        user: user,
        userService: userService,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      label: "Filtros",
                      onTap: () async {
                        final result = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FiltersPage(
                              initialRange: _selectedRange,
                              initialTypes: _selectedTypes,
                              onApplyFilters: (range, types) {
                                setState(() {
                                  _selectedRange = range;
                                  _selectedTypes = types;
                                });
                                _loadCorridas();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadCorridas,
                      child: _corridas.isEmpty
                          ? const EmptyState(
                              title: "Nenhuma corrida encontrada",
                              subtitle: "Tente ajustar os filtros ou aguarde novas corridas",
                              icon: Icons.motorcycle,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _corridas.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final solicitacao = _corridas[index];
                                final empresa = solicitacao.dbEmpresasByCodEmpresa?.desNomeFantasia ?? "Empresa";
                                final distancia = "${solicitacao.qtdKmCorrida ?? 0} km";
                                final valor = "R\$ ${solicitacao.vlrTotalMotorista?.toStringAsFixed(2) ?? "0.00"}";
                                final data = ApiBaseHelper.getDtaFormatada(solicitacao.dthSolicitacao);
                                final status = Utils.getDesStatusCorrida(solicitacao.indStatusCorrida);
                                final statusColor = Utils.getColorStatusCorrida(solicitacao.indStatusCorrida);
                                final isFinalizada = solicitacao.indStatusCorrida ==
                                        ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA ||
                                    solicitacao.indStatusCorrida ==
                                        ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA;
                                final actionLabel = Utils.getDesTextoProxStatusCorrida(solicitacao.indStatusCorrida ?? 0);

                                return CorridaCard(
                                  title: "$empresa - $data",
                                  distance: distancia,
                                  value: valor,
                                  status: status,
                                  statusColor: statusColor,
                                  actionLabel: actionLabel,
                                  showAction: !isFinalizada,
                                  onPrimaryAction: () {
                                    _handleAction(solicitacao);
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(SolicitacaoMotorista solicitacao) async {
    if (solicitacao.numSeq == null) return;

    final nextStatus = Utils.getDesStatusProxStatusCorrida(solicitacao.indStatusCorrida ?? 0);
    final text = Utils.getDesTextoProxStatusCorrida(solicitacao.indStatusCorrida ?? 0);

    // Se for cancelamento, usa dialog com motivo obrigatório
    if (nextStatus == ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA) {
      final motivo = await CancelCorridaDialog.show(
        context,
        corridaId: solicitacao.numSeq!.toString(),
        tituloCorrida: solicitacao.desEnderecoEntrega ?? 'Corrida #${solicitacao.numSeq}',
      );
      
      if (motivo != null && motivo.isNotEmpty) {
        await _controller.finalizarChamado(
          solicitacao.numSeq!,
          nextStatus,
          motivoCancelamento: motivo,
        );
        _loadCorridas();
      }
      return;
    }

    // Para outras ações, usa dialog simples
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar"),
        content: Text("Deseja realmente $text?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (solicitacao.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA) {
                final success = await _controller.aceitarCorrida(solicitacao.numSeq!, nextStatus);
                if (success) {
                  // Mensagem automática já é enviada no controller
                  _loadCorridas();
                }
              } else {
                await _controller.finalizarChamado(solicitacao.numSeq!, nextStatus);
                // Mensagem automática já é enviada no controller
                _loadCorridas();
              }
            },
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
  }
}
