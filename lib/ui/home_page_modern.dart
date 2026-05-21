import 'package:flutter/material.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/motorista/corridas/lista_solicitacoes_motorista_controller.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/shared/components/Utils.dart';
import 'theme_components.dart';
import 'app_drawer.dart';
import 'corrida_card.dart';
import 'empty_state.dart';

class HomePageModern extends StatefulWidget {
  final Usuario? user;

  const HomePageModern({Key? key, this.user}) : super(key: key);

  @override
  State<HomePageModern> createState() => _HomePageModernState();
}

class _HomePageModernState extends State<HomePageModern> with WidgetsBindingObserver {
  late ListaSolicitacoesMotoristaController _controller;
  List<SolicitacaoMotorista> _ultimasSolicitacoes = [];
  List<SolicitacaoMotorista> _novasCorridas = [];
  int _totalCorridas = 0;
  int _emAndamento = 0;
  int _concluidas = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ListaSolicitacoesMotoristaController(context);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Quando a tela volta ao foco, atualiza o status
      _updateUserStatus();
    }
  }

  void _updateUserStatus() {
    // Atualiza o estado quando o usuário volta para esta tela
    // Força rebuild para refletir mudanças no status do ApiBaseHelper
    if (mounted) {
      setState(() {
        // O build já pega o status atualizado do ApiBaseHelper.userSessao
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Atualiza quando a tela volta ao foco (ex: voltando do mapa)
    _updateUserStatus();
  }

  Future<void> _refreshUserStatus() async {
    // Busca dados atualizados do usuário do servidor
    try {
      final userService = UserService();
      final updatedUser = await userService.getCurrentUser();
      if (updatedUser != null) {
        // Atualiza o ApiBaseHelper com os dados mais recentes
        ApiBaseHelper.userSessao = updatedUser;
        await userService.saveLocalDB(updatedUser);
      }
    } catch (e) {
      // Se falhar, continua com os dados locais
      print('Erro ao atualizar status do usuário: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Buscar novas corridas
      final novasCorridas = await _controller.buscaListaSolicitacoes(
        indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA,
      );
      
      // Buscar corridas em andamento
      final emAndamentoList = await _controller.buscaListaSolicitacoes(
        indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO,
      );
      
      // Buscar corridas concluídas
      final concluidasList = await _controller.buscaListaSolicitacoes(
        indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA,
      );

      setState(() {
        _novasCorridas = novasCorridas;
        _ultimasSolicitacoes = novasCorridas.take(3).toList();
        _totalCorridas = novasCorridas.length + emAndamentoList.length + concluidasList.length;
        _emAndamento = emAndamentoList.length;
        _concluidas = concluidasList.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _porcentagemConclusao {
    if (_totalCorridas == 0) return 0.0;
    return _concluidas / _totalCorridas;
  }

  @override
  Widget build(BuildContext context) {
    // Sempre pega o usuário atualizado do ApiBaseHelper para refletir mudanças
    final user = ApiBaseHelper.userSessao ?? widget.user;
    final userService = UserService();
    // Status online/offline sincronizado com o que está no ApiBaseHelper
    // indOffline == 1 significa OFFLINE, indOffline == 0 ou null significa ONLINE
    final indOffline = user?.usuarioResp?.indOffline ?? 0;
    final isOnline = indOffline != 1;
    
    // Debug para verificar o status
    print('🏠 Home - indOffline: $indOffline, isOnline: $isOnline');

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppAppBar(
        title: user?.desNome ?? "Motorista",
        showBack: false,
      ),
      drawer: AppDrawer(
        user: user,
        userService: userService,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  // Atualiza o status do usuário antes de recarregar
                  await _refreshUserStatus();
                  await _loadData();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Header refinado
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: kPrimaryRed,
                            child: Text(
                              (user?.desNome?.isNotEmpty == true 
                                  ? user!.desNome!.toUpperCase().substring(0, 1) 
                                  : "M"),
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.desNome ?? "Motorista",
                                  style: kTitleStyle.copyWith(fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isOnline ? "Online" : "Offline",
                                  style: kSubtitleStyle.copyWith(
                                    color: isOnline ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                onPressed: () {
                                  // Navega para a página de novas corridas (notificações)
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.corridas,
                                    arguments: {
                                      'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA,
                                    },
                                  );
                                },
                                icon: Icon(Icons.notifications_none, color: Colors.black54),
                                tooltip: "Novas corridas",
                              ),
                              // Badge de notificação se houver novas corridas
                              if (_novasCorridas.isNotEmpty)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: kPrimaryRed,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      _novasCorridas.length > 9 ? '9+' : '${_novasCorridas.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: kSectionSpacing),

                      // Top metrics row
                      Row(
                        children: [
                          Expanded(
                            child: AppCard(
                              minHeight: kCardMinHeightSmall,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Total de corridas", style: kSubtitleStyle.copyWith(fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Text("$_totalCorridas", style: kNumberStyle),
                                    ],
                                  ),
                                  const Spacer(),
                                  Icon(Icons.motorcycle, color: kPrimaryRed, size: 28),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: FloatingActionButton(
                              backgroundColor: kPrimaryRed,
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.map);
                              },
                              child: Icon(Icons.add, color: Colors.white),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Two small metric cards
                      Row(
                        children: [
                          Expanded(
                            child: AppCard(
                              minHeight: kCardMinHeightSmall,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Corridas em andamento", style: kSubtitleStyle),
                                  const SizedBox(height: 8),
                                  Text("$_emAndamento", style: kNumberStyle.copyWith(fontSize: 20)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppCard(
                              minHeight: kCardMinHeightSmall,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Corridas concluídas", style: kSubtitleStyle),
                                  const SizedBox(height: 8),
                                  Text("$_concluidas", style: kNumberStyle.copyWith(fontSize: 20)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Section title + KPI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Números do mês", style: kTitleStyle),
                          Text("${(_porcentagemConclusao * 100).toStringAsFixed(1)}%", style: kSubtitleStyle),
                        ],
                      ),

                      const SizedBox(height: 12),

                      AppCard(
                        minHeight: kCardMinHeightLarge,
                        child: KpiCircle(
                          value: _totalCorridas,
                          label: "Corridas solicitadas",
                          size: 84,
                          ringWidth: 6,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Últimas solicitações (lista)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text("Últimas solicitações", style: kTitleStyle),
                        ),
                      ),

                      Expanded(
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          margin: EdgeInsets.zero,
                          minHeight: 120,
                          child: _ultimasSolicitacoes.isEmpty
                              ? const EmptyState(
                                  title: "Nenhuma solicitação disponível",
                                  subtitle: "Fique atento — novas corridas aparecem aqui",
                                  icon: Icons.motorcycle,
                                )
                              : ListView.separated(
                                  itemCount: _ultimasSolicitacoes.length,
                                              shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),

                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final solicitacao = _ultimasSolicitacoes[index];
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

                                    return CorridaCard(
                                      title: "$empresa - $data",
                                      distance: distancia,
                                      value: valor,
                                      status: status,
                                      statusColor: statusColor,
                                      actionLabel: isFinalizada ? "Ver" : "Aceitar",
                                      showAction: !isFinalizada,
                                      onPrimaryAction: () {
                                        if (!isFinalizada) {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.corridas,
                                            arguments: {
                                              'indTipoDefault': solicitacao.indStatusCorrida,
                                            },
                                          );
                                        }
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
      ),
    );
  }
}
