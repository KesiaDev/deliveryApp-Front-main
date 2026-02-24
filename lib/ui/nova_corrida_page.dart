import 'package:flutter/material.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/motorista/corridas/lista_solicitacoes_motorista_controller.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/shared/components/Utils.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'theme_components.dart';
import 'corrida_card.dart';
import 'empty_state.dart';

class NovaCorridaPage extends StatefulWidget {
  const NovaCorridaPage({Key? key}) : super(key: key);

  @override
  State<NovaCorridaPage> createState() => _NovaCorridaPageState();
}

class _NovaCorridaPageState extends State<NovaCorridaPage> {
  late ListaSolicitacoesMotoristaController _controller;
  List<SolicitacaoMotorista> _corridas = [];
  bool _isLoading = true;
  String _searchQuery = "";

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
        indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA,
      );
      setState(() {
        _corridas = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<SolicitacaoMotorista> get _filteredCorridas {
    if (_searchQuery.isEmpty) return _corridas;
    return _corridas.where((c) {
      final empresa = c.dbEmpresasByCodEmpresa?.desNomeFantasia ?? "";
      final endereco = c.enderecoEmpresa ?? "";
      return empresa.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          endereco.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: const AppAppBar(title: "Nova corrida", showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              AppCard(
                minHeight: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Pesquisar local",
                          isDense: true,
                          border: InputBorder.none,
                          suffixIcon: Icon(Icons.search, color: Colors.black38),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        onSubmitted: (v) {
                          // Busca já é feita em tempo real via onChanged
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // TODO: abrir geolocalização / proximidade
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.gps_fixed, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadCorridas,
                        child: _filteredCorridas.isEmpty
                            ? EmptyState(
                                title: _searchQuery.isEmpty
                                    ? "Nenhuma corrida disponível"
                                    : "Nenhuma corrida encontrada",
                                subtitle: _searchQuery.isEmpty
                                    ? "Fique atento — novas corridas aparecem aqui"
                                    : "Tente buscar com outros termos",
                                icon: Icons.motorcycle,
                              )
                            : ListView.separated(
                                itemCount: _filteredCorridas.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final solicitacao = _filteredCorridas[index];
                                  final empresa = solicitacao.dbEmpresasByCodEmpresa?.desNomeFantasia ?? "Empresa";
                                  final distancia = "${solicitacao.qtdKmCorrida ?? 0} km";
                                  final valor = "R\$ ${solicitacao.vlrTotalMotorista?.toStringAsFixed(2) ?? "0.00"}";
                                  final data = ApiBaseHelper.getDtaFormatada(solicitacao.dthSolicitacao);

                                  return CorridaCard(
                                    title: "$empresa - $data",
                                    distance: distancia,
                                    value: valor,
                                    status: "Disponível",
                                    statusColor: kPrimaryRed,
                                    actionLabel: "Aceitar",
                                    onPrimaryAction: () {
                                      _aceitarCorrida(solicitacao);
                                    },
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _aceitarCorrida(SolicitacaoMotorista solicitacao) async {
    if (solicitacao.numSeq == null) return;

    final nextStatus = Utils.getDesStatusProxStatusCorrida(solicitacao.indStatusCorrida ?? 0);
    final text = Utils.getDesTextoProxStatusCorrida(solicitacao.indStatusCorrida ?? 0);

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
      final success = await _controller.aceitarCorrida(solicitacao.numSeq!, nextStatus);
      if (success && mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.corridas,
          arguments: {
            'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO,
          },
        );
      }
    }
  }
}
