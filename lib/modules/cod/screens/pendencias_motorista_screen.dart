import 'dart:async';
import 'package:delivery_front/modules/cod/models/cod_model.dart';
import 'package:delivery_front/modules/cod/services/cod_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Tela de pendências financeiras do motorista
/// Mostra pendências abertas, vencidas e histórico de resolvidas
class PendenciasMotoristaScreen extends StatefulWidget {
  final int codMotorista;

  const PendenciasMotoristaScreen({Key? key, required this.codMotorista})
      : super(key: key);

  @override
  State<PendenciasMotoristaScreen> createState() =>
      _PendenciasMotoristaScreenState();
}

class _PendenciasMotoristaScreenState extends State<PendenciasMotoristaScreen> {
  static const _red = Color(0xFFE53935);
  static const _orange = Color(0xFFFB8C00);
  static const _green = Color(0xFF43A047);

  late Timer _clockTimer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    // Atualiza o contador a cada segundo para os timers de prazo
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _tick++);
    });
    // Verifica pendências vencidas ao abrir
    CodService.checkExpiredPendencies(widget.codMotorista);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5FA),
        appBar: AppBar(
          title: Text(
            'Pendências',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
          bottom: TabBar(
            labelColor: _red,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _red,
            tabs: const [
              Tab(text: 'Abertas / Vencidas'),
              Tab(text: 'Resolvidas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PendenciasTab(
              codMotorista: widget.codMotorista,
              statusFilter: ['aberta', 'vencida'],
              emptyMsg: 'Nenhuma pendência em aberto! ✓',
              tick: _tick,
            ),
            _PendenciasTab(
              codMotorista: widget.codMotorista,
              statusFilter: ['resolvida'],
              emptyMsg: 'Nenhuma pendência resolvida ainda.',
              tick: _tick,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendenciasTab extends StatelessWidget {
  final int codMotorista;
  final List<String> statusFilter;
  final String emptyMsg;
  final int tick; // Para forçar rebuild do timer

  const _PendenciasTab({
    required this.codMotorista,
    required this.statusFilter,
    required this.emptyMsg,
    required this.tick,
  });

  @override
  Widget build(BuildContext context) {
    final stream = CodService.streamPendencias(codMotorista);

    return StreamBuilder<List<PendenciaMotorista>>(
      stream: stream,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snap.data!;
        final filtered =
            all.where((p) => statusFilter.contains(p.status)).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusFilter.contains('resolvida')
                      ? Icons.history_rounded
                      : Icons.check_circle_rounded,
                  size: 56,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(emptyMsg,
                    style: GoogleFonts.poppins(
                        fontSize: 15, color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _PendenciaCard(
            pendencia: filtered[i],
            tick: tick,
          ),
        );
      },
    );
  }
}

class _PendenciaCard extends StatelessWidget {
  final PendenciaMotorista pendencia;
  final int tick;

  const _PendenciaCard({required this.pendencia, required this.tick});

  static const _red = Color(0xFFE53935);
  static const _orange = Color(0xFFFB8C00);
  static const _green = Color(0xFF43A047);

  Color get _borderColor {
    if (pendencia.isVencida) return _red;
    if (pendencia.minutosRestantes <= 10) return _orange;
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
    final min = pendencia.minutosRestantes;
    final secs = pendencia.prazoVencido
        ? 0
        : pendencia.dthPrazo.difference(DateTime.now()).inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: empresa + status
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pendencia.empresaName,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A))),
                  Text('Corrida #${pendencia.numSeq}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: const Color(0xFF757575))),
                ],
              ),
            ),
            _StatusChip(status: pendencia.status),
          ]),

          const SizedBox(height: 12),

          // Valor pendente
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: (pendencia.isVencida ? _red : _orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Devolver: ${fmt.format(pendencia.vlrPendente)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: pendencia.isVencida ? _red : _orange,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 10),

          // Timer de prazo (apenas para abertas)
          if (pendencia.isAberta && !pendencia.prazoVencido) ...[
            Row(children: [
              const Icon(Icons.timer_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Prazo: ${min.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: min <= 10 ? _orange : Colors.grey,
                  fontWeight: min <= 10 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            // Barra de progresso do timer
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: min / 60,
                backgroundColor: Colors.grey.shade200,
                color: min > 20
                    ? _green
                    : min > 10
                        ? _orange
                        : _red,
                minHeight: 6,
              ),
            ),
          ],

          if (pendencia.isVencida) ...[
            Row(children: [
              const Icon(Icons.lock_rounded, color: _red, size: 16),
              const SizedBox(width: 4),
              Text(
                'Prazo vencido — conta bloqueada até devolução',
                style: GoogleFonts.poppins(fontSize: 12, color: _red, fontWeight: FontWeight.w600),
              ),
            ]),
          ],

          if (pendencia.isResolvida) ...[
            Row(children: [
              const Icon(Icons.check_circle_rounded, color: _green, size: 16),
              const SizedBox(width: 4),
              Text(
                'Devolvido: ${fmt.format(pendencia.vlrDevolvido ?? 0)}',
                style: GoogleFonts.poppins(fontSize: 12, color: _green),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'aberta':
        color = const Color(0xFFFB8C00);
        label = '⚠️ Pendente';
        break;
      case 'vencida':
        color = const Color(0xFFE53935);
        label = '🔴 Vencida';
        break;
      case 'resolvida':
        color = const Color(0xFF43A047);
        label = '✓ Resolvida';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
