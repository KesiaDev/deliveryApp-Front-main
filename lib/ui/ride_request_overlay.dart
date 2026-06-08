import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:delivery_front/shared/components/Utils.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';

class RideRequestOverlay extends StatefulWidget {
  final SolicitacaoMotorista corrida;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RideRequestOverlay({
    Key? key,
    required this.corrida,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required SolicitacaoMotorista corrida,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RideRequestOverlay(
        corrida: corrida,
        onAccept: onAccept,
        onReject: onReject,
      ),
    );
  }

  @override
  State<RideRequestOverlay> createState() => _RideRequestOverlayState();
}

class _RideRequestOverlayState extends State<RideRequestOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;
  static const _timeout = 30;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _timeout),
    )..forward();

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // Timer esgotado: fecha o popup silenciosamente (sem navegar nem tocar som)
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        widget.onReject();
      }
    });

    _playAlertSound();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _playAlertSound() {
    // Usa o canal já inicializado no main.dart (fool_high_importance)
    try {
      FlutterLocalNotificationsPlugin().show(
        88888,
        '🛵 Nova corrida disponível!',
        'Toque para aceitar',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fool_high_importance',
            'Notificações Fool Entregas',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final corrida = widget.corrida;
    final ganho = Utils.formatBRL(corrida.vlrTotalMotorista);
    final distancia = corrida.qtdKmCorrida != null
        ? '${corrida.qtdKmCorrida!.toStringAsFixed(1)} km'
        : '';
    final retirada = corrida.enderecoEmpresa?.isNotEmpty == true
        ? corrida.enderecoEmpresa!
        : corrida.dbEmpresasByCodEmpresa?.desNomeFantasia ?? 'Local de retirada';
    final destino = corrida.desEnderecoEntrega != null
        ? '${corrida.desEnderecoEntrega}'
            '${corrida.desNumeroEndereco?.isNotEmpty == true ? ', ${corrida.desNumeroEndereco}' : ''}'
        : 'Destino não informado';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Timer bar
          AnimatedBuilder(
            animation: _timerController,
            builder: (_, __) {
              final remaining = (_timeout * (1 - _timerController.value)).ceil();
              return Column(
                children: [
                  LinearProgressIndicator(
                    value: 1 - _timerController.value,
                    backgroundColor: Colors.grey[200],
                    color: _timerController.value > 0.5 ? Colors.red : Colors.orange,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${remaining}s',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Valor em destaque (estilo Uber)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.motorcycle, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Nova corrida',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ganho,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                if (distancia.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      distancia,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Rota (retirada → entrega)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linha de rota
                  Column(
                    children: [
                      Icon(Icons.radio_button_checked, size: 20, color: Colors.orange.shade700),
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.grey[300],
                        ),
                      ),
                      const Icon(Icons.location_on, size: 20, color: Colors.red),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Retirada',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(retirada,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 16),
                        Text('Entrega',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(destino,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botões Recusar / Aceitar
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () {
                    if (mounted) Navigator.of(context).pop();
                    widget.onReject();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Recusar',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: () {
                    if (mounted) Navigator.of(context).pop();
                    widget.onAccept();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  child: const Text(
                    'ACEITAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
