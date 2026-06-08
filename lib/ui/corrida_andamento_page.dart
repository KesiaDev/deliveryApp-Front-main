import 'package:flutter/material.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/motorista/corridas/lista_solicitacoes_motorista_controller.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/shared/components/Utils.dart';
import 'package:delivery_front/shared/dialogs/cancel_corrida_dialog.dart';
import 'package:delivery_front/modules/navigation/screens/motorista_navigation_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme_components.dart';

class CorridaAndamentoPage extends StatefulWidget {
  final SolicitacaoMotorista solicitacao;
  final bool autoOpenNavigation;

  const CorridaAndamentoPage({
    Key? key,
    required this.solicitacao,
    this.autoOpenNavigation = false,
  }) : super(key: key);

  @override
  State<CorridaAndamentoPage> createState() => _CorridaAndamentoPageState();
}

class _CorridaAndamentoPageState extends State<CorridaAndamentoPage> {
  late ListaSolicitacoesMotoristaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ListaSolicitacoesMotoristaController(context);
    if (widget.autoOpenNavigation) {
      // Abre navegação GPS automaticamente após aceitar corrida
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _abrirNavegacao();
      });
    }
  }

  String get _empresa {
    return widget.solicitacao.dbEmpresasByCodEmpresa?.desNomeFantasia ?? "Empresa";
  }

  String get _endereco {
    if (widget.solicitacao.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ||
        widget.solicitacao.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA) {
      return widget.solicitacao.enderecoEmpresa ?? "Endereço não informado";
    }
    return "${widget.solicitacao.desEnderecoEntrega ?? ""} ${widget.solicitacao.desNumeroEndereco ?? ""}".trim();
  }

  String get _telefone {
    return widget.solicitacao.desTelefone ?? "";
  }

  bool get _isRetirada =>
      widget.solicitacao.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ||
      widget.solicitacao.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA;

  String get _proximaAcao {
    switch (widget.solicitacao.indStatusCorrida) {
      case 1: return "Cheguei ao local de retirada";
      case 2: return "Concluir Entrega";
      default: return "Finalizar Corrida";
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.solicitacao.indStatusCorrida ?? 0;
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppAppBar(
        title: _isRetirada ? "Indo buscar encomenda" : "Entregando encomenda",
        showBack: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Indicador de etapas
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _stepItem(icon: Icons.store, label: "Retirada", active: status <= 1, done: status > 1),
                    _stepLine(done: status > 1),
                    _stepItem(icon: Icons.motorcycle, label: "Em rota", active: status == 2, done: status > 2),
                    _stepLine(done: status > 2),
                    _stepItem(icon: Icons.check_circle, label: "Entregue", active: false, done: status == 3),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Card de destino atual
              AppCard(
                minHeight: kCardMinHeightSmall,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isRetirada ? Icons.store : Icons.location_on,
                          color: _isRetirada ? Colors.orange : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRetirada ? "Local de retirada" : "Local de entrega",
                          style: kSubtitleStyle.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(_empresa, style: kTitleStyle.copyWith(fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(_endereco, style: kSubtitleStyle),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: () => _abrirNavegacao(),
                            icon: const Icon(Icons.navigation, color: Colors.white, size: 18),
                            label: const Text("Navegar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        if (_telefone.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: () => _ligar(),
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text("Ligar"),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Observações + botão de avançar status
              AppCard(
                minHeight: kCardMinHeightSmall,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.solicitacao.desObsCorrida?.isNotEmpty == true) ...[
                      Text("Observações", style: kSubtitleStyle),
                      const SizedBox(height: 6),
                      Text(
                        widget.solicitacao.desObsCorrida!,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _finalizarCorrida(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRetirada ? Colors.orange : Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _proximaAcao,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepItem({required IconData icon, required String label, required bool active, required bool done}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: done ? Colors.green : active ? Colors.orange : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: done || active ? Colors.white : Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: done || active ? Colors.black87 : Colors.grey)),
      ],
    );
  }

  Widget _stepLine({required bool done}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
        color: done ? Colors.green : Colors.grey[300],
      ),
    );
  }

  Future<void> _abrirNavegacao() async {
    final corridaId = widget.solicitacao.numSeq?.toString() ?? '';
    final numSeq = widget.solicitacao.numSeq;
    final isRetirada =
        widget.solicitacao.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ||
        widget.solicitacao.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA;

    try {
      if (isRetirada) {
        // ── ETAPA 1: ir até a empresa buscar a encomenda ──────────────────
        double? lat = widget.solicitacao.dbEmpresasByCodEmpresa?.desLatitude;
        double? lng = widget.solicitacao.dbEmpresasByCodEmpresa?.desLongitude;

        if ((lat == null || lng == null) && widget.solicitacao.enderecoEmpresa != null) {
          final locs = await locationFromAddress(widget.solicitacao.enderecoEmpresa!);
          if (locs.isNotEmpty) { lat = locs.first.latitude; lng = locs.first.longitude; }
        }

        if (lat == null || lng == null || !mounted) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Endereço de retirada não disponível')));
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MotoristaNavigationScreen(
              corridaId: corridaId,
              destinationLat: lat!,
              destinationLng: lng!,
              destinationTitle: widget.solicitacao.enderecoEmpresa ?? 'Local de retirada',
              destinationType: 'pickup',
              actionLabel: 'Retirei o pedido!',
              onArrived: numSeq == null ? null : () async {
                // Muda status para "Em andamento" (2)
                await _controller.finalizarChamado(
                  numSeq,
                  ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO,
                );
                // Atualiza status local para a próxima etapa
                widget.solicitacao.indStatusCorrida =
                    ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO;
              },
            ),
          ),
        );

        // Após sair da navegação de retirada, se status já é 2 → abre entrega
        if (!mounted) return;
        if (widget.solicitacao.indStatusCorrida ==
            ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO) {
          await _abrirNavegacaoEntrega(corridaId, numSeq);
        }
      } else {
        // Chamado direto para entrega (ex: botão "Navegar" na CorridaAndamentoPage)
        await _abrirNavegacaoEntrega(corridaId, numSeq);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao abrir navegação')));
    }
  }

  Future<void> _abrirNavegacaoEntrega(String corridaId, int? numSeq) async {
    // ── ETAPA 2: ir até o cliente entregar ───────────────────────────────
    double? lat = widget.solicitacao.desLatitudeEntrega;
    double? lng = widget.solicitacao.desLongitudeEntrega;

    if ((lat == null || lng == null) && widget.solicitacao.desEnderecoEntrega != null) {
      final addr =
          '${widget.solicitacao.desEnderecoEntrega}, ${widget.solicitacao.desNumeroEndereco ?? ''}';
      final locs = await locationFromAddress(addr);
      if (locs.isNotEmpty) {
        lat = locs.first.latitude;
        lng = locs.first.longitude;
        widget.solicitacao.desLatitudeEntrega = lat;
        widget.solicitacao.desLongitudeEntrega = lng;
      }
    }

    if (lat == null || lng == null || !mounted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endereço de entrega não disponível')));
      return;
    }

    final title =
        '${widget.solicitacao.desEnderecoEntrega ?? 'Entrega'}'
        '${widget.solicitacao.desNumeroEndereco != null ? ', ${widget.solicitacao.desNumeroEndereco}' : ''}';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MotoristaNavigationScreen(
          corridaId: corridaId,
          destinationLat: lat!,
          destinationLng: lng!,
          destinationTitle: title,
          destinationType: 'delivery',
          actionLabel: 'Entrega realizada!',
          onArrived: numSeq == null ? null : () async {
            // Muda status para "Concluída" (3)
            await _controller.finalizarChamado(
              numSeq,
              ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA,
            );
            widget.solicitacao.indStatusCorrida =
                ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA;
          },
        ),
      ),
    );

    // Após entrega confirmada → volta para home
    if (mounted &&
        widget.solicitacao.indStatusCorrida ==
            ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _ligar() async {
    if (_telefone.isEmpty) return;
    final url = "tel:$_telefone";
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _finalizarCorrida() async {
    if (widget.solicitacao.numSeq == null) return;

    final nextStatus = Utils.getDesStatusProxStatusCorrida(widget.solicitacao.indStatusCorrida ?? 0);
    final text = Utils.getDesTextoProxStatusCorrida(widget.solicitacao.indStatusCorrida ?? 0);

    // Se for cancelamento, usa dialog com motivo obrigatório
    if (nextStatus == ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA) {
      final motivo = await CancelCorridaDialog.show(
        context,
        corridaId: widget.solicitacao.numSeq!.toString(),
        tituloCorrida: widget.solicitacao.desEnderecoEntrega ?? 'Corrida #${widget.solicitacao.numSeq}',
      );
      
      if (motivo != null && motivo.isNotEmpty) {
        await _controller.finalizarChamado(
          widget.solicitacao.numSeq!,
          nextStatus,
          motivoCancelamento: motivo,
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
      return;
    }

    // Para outras ações, usa dialog simples
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar"),
        content: Text("Deseja realmente $text?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _controller.finalizarChamado(widget.solicitacao.numSeq!, nextStatus);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
