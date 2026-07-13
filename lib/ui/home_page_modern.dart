import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/motorista/corridas/lista_solicitacoes_motorista_controller.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/shared/components/Utils.dart';
import 'package:delivery_front/shared/services/local_storage_service.dart';
import 'package:delivery_front/modules/cod/models/cod_model.dart';
import 'package:delivery_front/modules/cod/screens/pendencias_motorista_screen.dart';
import 'package:delivery_front/modules/cod/services/cod_service.dart';
import 'theme_components.dart';
import 'app_drawer.dart';
import 'corrida_card.dart';
import 'empty_state.dart';
import 'ride_request_overlay.dart';
import 'corrida_andamento_page.dart';
import 'package:delivery_front/ui/corridas_list_page.dart';

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
  List<SolicitacaoMotorista> _ativasList = []; // status 1 (aceita) + 2 (em andamento)
  int _totalCorridas = 0;
  int _emAndamento = 0;
  int _concluidas = 0;
  bool _isLoading = true;

  /// Primeira corrida ativa (aceita ou em andamento) — para o banner de retorno
  SolicitacaoMotorista? get _corridaAtiva =>
      _ativasList.isNotEmpty ? _ativasList.first : null;

  // Polling para novas corridas
  Timer? _pollTimer;
  final Set<int> _shownRideIds = {};
  bool _isOverlayShowing = false;

  // COD — pendências de cobrança na entrega
  List<PendenciaMotorista> _pendenciasCod = [];
  StreamSubscription<List<PendenciaMotorista>>? _codSub;
  Timer? _codCountdownTimer;
  // Atualizado a cada segundo para forçar rebuild do countdown
  int _codTick = 0;

  // Persistência de corridas mostradas para evitar repetição ao reabrir app
  static const String _SHOWN_RIDES_KEY = 'motorista_shown_ride_ids';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ListaSolicitacoesMotoristaController(context);
    _startCodStream();
    // Garante que os IDs de corridas já recusadas são carregados ANTES de
    // buscar novas corridas, evitando que corridas recusadas reapareçam.
    _loadShownRideIds().then((_) {
      if (mounted) {
        _loadData();
        _startPolling();
      }
    });
  }

  void _startCodStream() {
    final codMotorista = ApiBaseHelper.userSessao?.codUsuario;
    if (codMotorista == null) return;
    _codSub = CodService.streamPendencias(codMotorista).listen((pends) {
      if (!mounted) return;
      setState(() => _pendenciasCod = pends);
      // Inicia timer de 1 seg apenas se houver pendência aberta
      if (pends.any((p) => p.isAberta) && _codCountdownTimer == null) {
        _codCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _codTick++);
          // Para o timer se não há mais pendências abertas
          if (_pendenciasCod.every((p) => !p.isAberta)) {
            _codCountdownTimer?.cancel();
            _codCountdownTimer = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _codSub?.cancel();
    _codCountdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadShownRideIds() async {
    try {
      final jsonStr = await LocalStorageService.getString(_SHOWN_RIDES_KEY);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final ids = jsonStr.split(',').map((s) => int.tryParse(s)).whereType<int>();
        _shownRideIds.addAll(ids);
      }
    } catch (_) {}
  }

  Future<void> _saveShownRideId(int id) async {
    _shownRideIds.add(id);
    await LocalStorageService.setString(
      _SHOWN_RIDES_KEY,
      _shownRideIds.join(','),
    );
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _checkForNewRides();
    });
  }

  Future<void> _checkForNewRides() async {
    if (_isOverlayShowing) return;
    try {
      final novas = await _controller.buscaListaSolicitacoes(
        indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA,
      );
      for (final corrida in novas) {
        final id = corrida.numSeq ?? -1;
        if (id > 0 && !_shownRideIds.contains(id)) {
          await _saveShownRideId(id);
          if (mounted) _showRideRequestOverlay(corrida);
          break;
        }
      }
      // Atualiza badge de novas corridas
      if (mounted && novas.length != _novasCorridas.length) {
        setState(() => _novasCorridas = novas);
      }
    } catch (_) {}
  }

  void _showRideRequestOverlay(SolicitacaoMotorista corrida) {
    if (!mounted) return;
    if (corrida.numSeq == null) return;
    _isOverlayShowing = true;
    RideRequestOverlay.show(
      context,
      corrida: corrida,
      onAccept: () async {
        _isOverlayShowing = false;
        final sucess = await _controller.aceitarCorrida(
          corrida.numSeq!,
          ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA,
        );
        if (sucess && mounted) {
          corrida.indStatusCorrida = ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA;
          _loadData();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CorridaAndamentoPage(
                solicitacao: corrida,
                autoOpenNavigation: true,
              ),
            ),
          );
        }
      },
      onReject: () {
        _isOverlayShowing = false;
      },
    );
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
    if (mounted) setState(() => _isLoading = true);

    List<SolicitacaoMotorista> novasCorridas = [];
    List<SolicitacaoMotorista> emAndamentoList = [];
    List<SolicitacaoMotorista> concluidasList = [];

    try {
      novasCorridas = await _controller
          .buscaListaSolicitacoes(indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA)
          .timeout(const Duration(seconds: 12), onTimeout: () => []);
    } catch (_) {}

    List<SolicitacaoMotorista> aceitasList = [];
    try {
      aceitasList = await _controller
          .buscaListaSolicitacoes(indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA)
          .timeout(const Duration(seconds: 12), onTimeout: () => []);
    } catch (_) {}

    try {
      emAndamentoList = await _controller
          .buscaListaSolicitacoes(indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO)
          .timeout(const Duration(seconds: 12), onTimeout: () => []);
    } catch (_) {}

    try {
      concluidasList = await _controller
          .buscaListaSolicitacoes(indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA)
          .timeout(const Duration(seconds: 12), onTimeout: () => []);
    } catch (_) {}

    if (!mounted) {
      _isLoading = false;
      return;
    }

    setState(() {
      _novasCorridas = novasCorridas;
      _ultimasSolicitacoes = novasCorridas;
      _ativasList = [...aceitasList, ...emAndamentoList];
      _totalCorridas = novasCorridas.length + emAndamentoList.length + concluidasList.length;
      _emAndamento = emAndamentoList.length + aceitasList.length;
      _concluidas = concluidasList.length;
      _isLoading = false;
    });

    // Mostra overlay para a primeira corrida disponível ao abrir o app
    if (novasCorridas.isNotEmpty && !_isOverlayShowing) {
      final corrida = novasCorridas.first;
      final id = corrida.numSeq ?? -1;
      if (id > 0 && !_shownRideIds.contains(id)) {
        await _saveShownRideId(id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (mounted) _showRideRequestOverlay(corrida);
          } catch (_) {}
        });
      }
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

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar'),
            content: const Text('Deseja fechar o app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Não'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sim', style: TextStyle(color: Color(0xFFE53935))),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        title: user?.desNome ?? "Motorista",
        showBack: false,
      ),
      drawer: AppDrawer(
        user: user,
        userService: userService,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── BANNER DE CORRIDA ATIVA ─────────────────────────────────────
            if (_corridaAtiva != null) _buildActiveBanner(_corridaAtiva!),

            // ── BANNER COD — countdown devolução ───────────────────────────
            if (_pendenciasCod.isNotEmpty) _buildCodCountdownBanner(),

            // ── CONTEÚDO PRINCIPAL ──────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                onRefresh: () async {
                  // Atualiza o status do usuário antes de recarregar
                  await _refreshUserStatus();
                  await _loadData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                    color: isOnline ? Colors.green : onSurface.withOpacity(0.5),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CorridasListPage(
                                        indTipoDefault: ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA,
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.notifications_none, color: onSurface.withOpacity(0.54)),
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

                      _ultimasSolicitacoes.isEmpty
                          ? AppCard(
                              padding: const EdgeInsets.all(12),
                              margin: EdgeInsets.zero,
                              minHeight: 120,
                              child: const EmptyState(
                                title: "Nenhuma solicitação disponível",
                                subtitle: "Fique atento — novas corridas aparecem aqui",
                                icon: Icons.motorcycle,
                              ),
                            )
                          : Column(
                              children: [
                                for (int index = 0; index < _ultimasSolicitacoes.length; index++) ...[
                                  Builder(builder: (context) {
                                    final solicitacao = _ultimasSolicitacoes[index];
                                    final empresa = solicitacao.dbEmpresasByCodEmpresa?.desNomeFantasia ?? "Empresa";
                                    final distancia = "${solicitacao.qtdKmCorrida ?? 0} km";
                                    final valor = Utils.formatBRL(solicitacao.vlrTotalMotorista);
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
                                  }),
                                  if (index < _ultimasSolicitacoes.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ), // Expanded
          ],
        ), // Column
      ),
    ), // Scaffold
    ); // PopScope
  }

  // ── Banner COD — contagem regressiva para devolução ──────────────────────

  Widget _buildCodCountdownBanner() {
    // Pega a pendência mais urgente (menor prazo)
    final pend = _pendenciasCod.reduce((a, b) =>
        a.dthPrazo.isBefore(b.dthPrazo) ? a : b);

    final diff = pend.dthPrazo.difference(DateTime.now());
    final totalSecs = diff.inSeconds;
    final vencido = totalSecs <= 0;

    final mins = vencido ? 0 : (totalSecs ~/ 60);
    final secs = vencido ? 0 : (totalSecs % 60);
    final countdownStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // Cor muda conforme urgência
    final Color bgColor = vencido
        ? const Color(0xFFB71C1C)
        : totalSecs < 600
            ? const Color(0xFFE53935) // menos de 10 min — vermelho
            : const Color(0xFFE65100); // mais de 10 min — laranja escuro

    return GestureDetector(
      onTap: () {
        final cod = ApiBaseHelper.userSessao?.codUsuario;
        if (cod == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PendenciasMotoristaScreen(codMotorista: cod),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Ícone pulsante
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vencido
                        ? '⛔ Prazo vencido — novas corridas bloqueadas'
                        : '💰 Devolva R\$ ${pend.vlrPendente.toStringAsFixed(2).replaceAll('.', ',')} para ${pend.empresaName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    vencido
                        ? 'Entre em contato com a empresa imediatamente'
                        : 'Tempo restante para devolver: $countdownStr',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Contador grande
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                vencido ? 'VENCIDO' : countdownStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Banner de corrida ativa ────────────────────────────────────────────────

  Widget _buildActiveBanner(SolicitacaoMotorista corrida) {
    final isRetirada = corrida.indStatusCorrida ==
        ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA;
    final label = isRetirada ? 'Indo buscar encomenda' : 'Entregando encomenda';
    final empresa = corrida.dbEmpresasByCodEmpresa?.desNomeFantasia ?? '';
    final destino = corrida.desEnderecoEntrega ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CorridaAndamentoPage(
              solicitacao: corrida,
              autoOpenNavigation: false,
            ),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isRetirada
              ? const Color(0xFFFF6F00)  // laranja para retirada
              : const Color(0xFF2E7D32), // verde para entrega
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.motorcycle_rounded, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (empresa.isNotEmpty || destino.isNotEmpty)
                    Text(
                      empresa.isNotEmpty ? empresa : destino,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Retomar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
