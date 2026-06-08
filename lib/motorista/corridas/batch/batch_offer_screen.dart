import 'package:delivery_front/motorista/corridas/batch/batch_group_model.dart';
import 'package:delivery_front/motorista/corridas/batch/batch_service.dart';
import 'package:flutter/material.dart';

/// Tela de oferta de entrega agrupada (batch).
/// Exibida quando o sistema detecta a oportunidade de agrupar entregas.
///
/// Uso:
/// ```dart
/// final aceito = await Navigator.push<bool>(
///   context,
///   MaterialPageRoute(builder: (_) => BatchOfferScreen(
///     group: batchGroupModel,
///     corridaPrincipalId: X,
///     motoristaId: Y,
///   )),
/// );
/// ```
class BatchOfferScreen extends StatefulWidget {
  final BatchGroupModel group;
  final int corridaPrincipalId;
  final int motoristaId;
  final Duration timeoutDuration;

  const BatchOfferScreen({
    Key? key,
    required this.group,
    required this.corridaPrincipalId,
    required this.motoristaId,
    this.timeoutDuration = const Duration(minutes: 4),
  }) : super(key: key);

  @override
  State<BatchOfferScreen> createState() => _BatchOfferScreenState();
}

class _BatchOfferScreenState extends State<BatchOfferScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: widget.timeoutDuration,
    )..forward();

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _rejeitar(auto: true);
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _aceitar() async {
    setState(() => _loading = true);
    final g = widget.group;
    final secundaria = g.items.firstWhere(
      (i) => !i.isPrincipal,
      orElse: () => g.items.last,
    );
    final ok = await BatchService.criarGrupo(
      corridaPrincipalId: widget.corridaPrincipalId,
      corridaSecundariaId: secundaria.corridaId,
      motoristaId: widget.motoristaId,
    );
    if (mounted) {
      Navigator.of(context).pop(ok);
    }
  }

  Future<void> _rejeitar({bool auto = false}) async {
    if (widget.group.groupId != null) {
      await BatchService.rejeitarGrupo(widget.group.groupId!);
    }
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final principal = g.items.firstWhere(
      (i) => i.isPrincipal,
      orElse: () => g.items.first,
    );
    final secundaria = g.items.firstWhere(
      (i) => !i.isPrincipal,
      orElse: () => g.items.last,
    );

    return WillPopScope(
      onWillPop: () async {
        await _rejeitar();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildTimer(),
                const SizedBox(height: 20),
                _buildEarningsBanner(g),
                const SizedBox(height: 16),
                Expanded(child: _buildRouteCard(principal, secundaria, g)),
                const SizedBox(height: 16),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delivery_dining,
              color: Color(0xFFFF6B35), size: 28),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrega Agrupada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Faça 2 entregas de uma vez e ganhe mais!',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimer() {
    return AnimatedBuilder(
      animation: _timerController,
      builder: (_, __) {
        final seconds =
            ((1 - _timerController.value) * widget.timeoutDuration.inSeconds)
                .ceil();
        final mins = seconds ~/ 60;
        final secs = seconds % 60;
        final label = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
        final color = seconds < 30
            ? const Color(0xFFFF4444)
            : const Color(0xFFFF6B35);

        return Row(
          children: [
            Icon(Icons.timer, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              'Oferta expira em $label',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: 1 - _timerController.value,
                backgroundColor: Colors.white12,
                color: color,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEarningsBanner(BatchGroupModel g) {
    final pct = g.items.length > 1 && g.items[1].fatorReducao < 1.0
        ? (g.items[1].fatorReducao * 100).toStringAsFixed(0)
        : '73';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Você recebe',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                'R\$ ${g.totalEntregador.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                '2ª entrega com fator $pct%',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          if (g.ganhoHoraEstimado != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Ganho/hora estimado',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                Text(
                  'R\$ ${g.ganhoHoraEstimado!.toStringAsFixed(2)}/h',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(
      BatchItemModel principal, BatchItemModel secundaria, BatchGroupModel g) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rota de Entregas',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 16),
          _buildStop(
            numero: '1',
            color: const Color(0xFF4CAF50),
            label: 'Entrega Principal',
            endereco: principal.desEnderecoEntrega ?? 'Endereço da corrida #${principal.corridaId}',
            valor: 'R\$ ${principal.vlrEntregador.toStringAsFixed(2)}',
            extra: null,
          ),
          _buildConnector(),
          _buildStop(
            numero: '2',
            color: const Color(0xFF2196F3),
            label: 'Entrega Extra',
            endereco: secundaria.desEnderecoEntrega ?? 'Endereço da corrida #${secundaria.corridaId}',
            valor: 'R\$ ${secundaria.vlrEntregador.toStringAsFixed(2)}',
            extra: secundaria.distanciaExtraKm > 0
                ? '+${secundaria.distanciaExtraKm.toStringAsFixed(1)} km · +${secundaria.tempoExtraMin} min'
                : null,
          ),
          const Divider(color: Colors.white12, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(Icons.straighten,
                  '${g.distanciaExtraKm?.toStringAsFixed(1) ?? '?'} km extra',
                  Colors.white60),
              _buildStat(Icons.schedule,
                  '+${g.tempoExtraMin ?? 0} min', Colors.white60),
              _buildStat(Icons.local_shipping, '2 paradas', Colors.white60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStop({
    required String numero,
    required Color color,
    required String label,
    required String endereco,
    required String valor,
    String? extra,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withOpacity(0.2),
              child: Text(numero,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(endereco,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              if (extra != null) ...[
                const SizedBox(height: 2),
                Text(extra,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ],
          ),
        ),
        Text(valor,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  Widget _buildConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 13, top: 4, bottom: 4),
      child: Container(width: 2, height: 20, color: Colors.white12),
    );
  }

  Widget _buildStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }

  Widget _buildButtons() {
    return _loading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
        : Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejeitar(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Só uma entrega',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _aceitar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Aceitar Agrupamento',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),
            ],
          );
  }
}
