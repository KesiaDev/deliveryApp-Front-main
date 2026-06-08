import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import './corrida_monitor_screen.dart';

/// Tela de simulação: cria uma corrida no Firestore e simula
/// a moto se movendo em tempo real para testar o CorridaMonitorScreen.
class RideSimulatorScreen extends StatefulWidget {
  final String adminId;
  final String adminName;

  const RideSimulatorScreen({
    Key? key,
    required this.adminId,
    required this.adminName,
  }) : super(key: key);

  @override
  State<RideSimulatorScreen> createState() => _RideSimulatorScreenState();
}

class _RideSimulatorScreenState extends State<RideSimulatorScreen> {
  static const Color _red = Color(0xFFE53935);
  static const Color _textPrimary = Color(0xFF1A1A1A);

  Timer? _timer;
  bool _isRunning = false;
  int _stepIndex = 0;
  String? _corridaId;
  String _statusText = 'Pronto para simular';

  // Rota simulada em São Paulo: Rua das Flores → Rua das Palmeiras
  static const List<List<double>> _route = [
    [-23.5478, -46.6361],
    [-23.5483, -46.6368],
    [-23.5489, -46.6377],
    [-23.5494, -46.6389],
    [-23.5498, -46.6402],
    [-23.5500, -46.6418],
    [-23.5501, -46.6432],
    [-23.5502, -46.6448],
  ];

  static const String _motoristaId = 'drv_sim_032';
  static const String _motoristaName = 'Lucas Ferreira';
  static const String _clienteId = 'clt_sim_joao';
  static const String _clienteName = 'João Silva';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startSimulation() async {
    setState(() {
      _isRunning = true;
      _stepIndex = 0;
      _statusText = 'Criando corrida no Firestore...';
    });

    // Gera ID único para a corrida simulada
    final id = 'sim_${DateTime.now().millisecondsSinceEpoch}';
    final trackingRef =
        FirebaseFirestore.instance.collection('tracking').doc(id);

    // Inicializa o documento de tracking (formato esperado pelo TrackingService)
    await trackingRef.set({
      'corridaId': id,
      'userId': _motoristaId,
      'motoristaId': _motoristaId,
      'motoristaName': _motoristaName,
      'clienteId': _clienteId,
      'clienteName': _clienteName,
      'status': 'em_andamento',
      'lastLatitude': _route[0][0],
      'lastLongitude': _route[0][1],
      'lastUpdate': FieldValue.serverTimestamp(),
    });

    setState(() {
      _corridaId = id;
      _statusText = 'Corrida criada. Moto saindo...';
    });

    // Avança posição a cada 2 segundos
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_stepIndex >= _route.length) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isRunning = false;
            _statusText = '✅ Entrega concluída!';
          });
        }
        return;
      }

      final pos = _route[_stepIndex];
      final speed = _stepIndex == 0 ? 0.0 : 8.3; // ~30 km/h em m/s
      final heading = _calcHeading(_stepIndex);

      // Atualiza posição atual no documento principal
      await trackingRef.update({
        'lastLatitude': pos[0],
        'lastLongitude': pos[1],
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      // Adiciona entrada na subcoleção (formato que TrackingService escuta)
      await trackingRef.collection('locations').add({
        'corridaId': id,
        'userId': _motoristaId,
        'latitude': pos[0],
        'longitude': pos[1],
        'speed': speed,
        'heading': heading,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _stepIndex++;
          _statusText =
              'Passo $_stepIndex/${_route.length} — ${pos[0].toStringAsFixed(4)}, ${pos[1].toStringAsFixed(4)}';
        });
      }
    });
  }

  double _calcHeading(int index) {
    if (index == 0 || index >= _route.length) return 180.0;
    final curr = _route[index - 1];
    final next = _route[index];
    final dLat = next[0] - curr[0];
    final dLng = next[1] - curr[1];
    if (dLng.abs() > dLat.abs()) return dLng > 0 ? 90.0 : 270.0;
    return dLat > 0 ? 0.0 : 180.0;
  }

  void _stopSimulation() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _statusText = 'Simulação parada';
    });
  }

  void _openMonitor() {
    if (_corridaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie a simulação primeiro!')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CorridaMonitorScreen(
          corridaId: _corridaId!,
          motoristaId: _motoristaId,
          motoristaName: _motoristaName,
          clienteId: _clienteId,
          clienteName: _clienteName,
          adminId: widget.adminId,
          adminName: widget.adminName,
          initialLat: _route[0][0],
          initialLng: _route[0][1],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: Text(
          'Simulador de Corrida',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de info da corrida
            _InfoCard(
              motoristaName: _motoristaName,
              clienteName: _clienteName,
              statusText: _statusText,
              corridaId: _corridaId,
            ),
            const SizedBox(height: 24),

            // Título da rota
            Text(
              'Rota simulada (${_route.length} pontos)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Visualização dos pontos da rota
            ...List.generate(_route.length, (i) {
              final isActive = i == _stepIndex - 1 && _isRunning;
              final isDone = i < _stepIndex;
              return _RouteStep(
                index: i,
                position: _route[i],
                isActive: isActive,
                isDone: isDone,
                isFirst: i == 0,
                isLast: i == _route.length - 1,
              );
            }),

            const SizedBox(height: 32),

            // Botões
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? _stopSimulation : _startSimulation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isRunning ? Colors.orange.shade700 : _red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      _isRunning
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      _isRunning ? 'Parar' : 'Iniciar',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openMonitor,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: _red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_rounded),
                    label: Text(
                      'Ver ao Vivo',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Dica
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toque em "Iniciar" e depois "Ver ao Vivo" para abrir o monitor. '
                      'A moto vai se mover no mapa a cada 2 segundos. '
                      'Você pode enviar mensagens nos dois chats!',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String motoristaName;
  final String clienteName;
  final String statusText;
  final String? corridaId;

  const _InfoCard({
    required this.motoristaName,
    required this.clienteName,
    required this.statusText,
    this.corridaId,
  });

  static const Color _red = Color(0xFFE53935);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.motorcycle_rounded,
                    color: _red, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Corrida Demo',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'Rua das Flores → Rua das Palmeiras',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _row(Icons.person_outline_rounded, 'Motorista',
              '$motoristaName ⭐ 4.9'),
          const SizedBox(height: 6),
          _row(Icons.shopping_bag_outlined, 'Cliente', clienteName),
          const SizedBox(height: 6),
          _row(Icons.info_outline_rounded, 'Status', statusText),
          if (corridaId != null) ...[
            const SizedBox(height: 6),
            _row(Icons.tag_rounded, 'ID',
                corridaId!.length > 20 ? corridaId!.substring(0, 20) : corridaId!),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _textSecondary),
        const SizedBox(width: 7),
        Text('$label: ',
            style: GoogleFonts.poppins(
                fontSize: 12, color: _textSecondary)),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _textPrimary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RouteStep extends StatelessWidget {
  final int index;
  final List<double> position;
  final bool isActive;
  final bool isDone;
  final bool isFirst;
  final bool isLast;

  const _RouteStep({
    required this.index,
    required this.position,
    required this.isActive,
    required this.isDone,
    required this.isFirst,
    required this.isLast,
  });

  static const Color _red = Color(0xFFE53935);
  static const Color _textSecondary = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDone
                  ? Colors.green
                  : isActive
                      ? _red
                      : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : isActive
                      ? const Icon(Icons.motorcycle_rounded,
                          size: 14, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${position[0].toStringAsFixed(4)}, ${position[1].toStringAsFixed(4)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDone
                    ? Colors.green.shade700
                    : isActive
                        ? _red
                        : _textSecondary,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isFirst)
            _Chip('origem', Colors.blue)
          else if (isLast)
            _Chip('destino', Colors.green),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
            fontSize: 10,
            color: color.shade700,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }
}
