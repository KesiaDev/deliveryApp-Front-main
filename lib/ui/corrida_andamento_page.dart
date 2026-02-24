import 'package:flutter/material.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/motorista/corridas/lista_solicitacoes_motorista_controller.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/shared/components/Utils.dart';
import 'package:delivery_front/shared/dialogs/cancel_corrida_dialog.dart';
import 'package:delivery_front/home/widgets/maps/mapsSheet.dart';
import 'package:geocoding/geocoding.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme_components.dart';

class CorridaAndamentoPage extends StatefulWidget {
  final SolicitacaoMotorista solicitacao;

  const CorridaAndamentoPage({Key? key, required this.solicitacao}) : super(key: key);

  @override
  State<CorridaAndamentoPage> createState() => _CorridaAndamentoPageState();
}

class _CorridaAndamentoPageState extends State<CorridaAndamentoPage> {
  late ListaSolicitacoesMotoristaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ListaSolicitacoesMotoristaController(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: const AppAppBar(title: "Corrida em andamento", showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppCard(
                minHeight: kCardMinHeightSmall,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_empresa, style: kTitleStyle),
                    const SizedBox(height: 8),
                    Text(_endereco, style: kSubtitleStyle),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ActionButton(
                            label: "Navegar",
                            onTap: () => _abrirNavegacao(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _telefone.isNotEmpty ? () => _ligar() : null,
                            child: const Text("Ligar"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                minHeight: kCardMinHeightSmall,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Observações", style: kSubtitleStyle),
                    const SizedBox(height: 8),
                    Text(
                      widget.solicitacao.desObsCorrida ?? "Nenhuma observação",
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    ActionButton(
                      label: "Finalizar Corrida",
                      onTap: () => _finalizarCorrida(),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirNavegacao() async {
    try {
      if (widget.solicitacao.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ||
          widget.solicitacao.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA) {
        // Navegar para empresa (retirada)
        if (widget.solicitacao.dbEmpresasByCodEmpresa?.desLatitude != null &&
            widget.solicitacao.dbEmpresasByCodEmpresa?.desLongitude != null) {
          MapsSheet.show(
            context: context,
            onMapTap: (map) {
              map.showDirections(
                destinationTitle: "${widget.solicitacao.enderecoEmpresa} - Pedido retirada",
                destination: Coords(
                  widget.solicitacao.dbEmpresasByCodEmpresa!.desLatitude!,
                  widget.solicitacao.dbEmpresasByCodEmpresa!.desLongitude!,
                ),
              );
            },
          );
        }
      } else {
        // Navegar para entrega
        double? lat = widget.solicitacao.desLatitudeEntrega;
        double? lng = widget.solicitacao.desLongitudeEntrega;

        if (lat == null || lng == null) {
          // Tentar geocodificar endereço
          try {
            final locations = await locationFromAddress(
              "${widget.solicitacao.desEnderecoEntrega}, ${widget.solicitacao.desNumeroEndereco}",
            );
            if (locations.isNotEmpty) {
              lat = locations.first.latitude;
              lng = locations.first.longitude;
            }
          } catch (e) {
            // Erro ao geocodificar
          }
        }

        if (lat != null && lng != null) {
          MapsSheet.show(
            context: context,
            onMapTap: (map) {
              map.showDirections(
                destinationTitle: "${widget.solicitacao.desEnderecoEntrega} - Entrega",
                destination: Coords(lat!, lng!),
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Não é possível iniciar navegação. Faltam informações do endereço")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao abrir navegação")),
      );
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
