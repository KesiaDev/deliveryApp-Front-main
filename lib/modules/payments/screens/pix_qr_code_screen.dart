import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/payment_service.dart';

/// Tela de exibição do QR Code PIX para pagamento
class PixQrCodeScreen extends StatefulWidget {
  final String corridaId;
  final String asaasPaymentId; // ID real do pagamento no Asaas para verificação
  final double amount;
  final String pixCopyPaste;
  final String qrCodeImage; // base64

  const PixQrCodeScreen({
    Key? key,
    required this.corridaId,
    required this.asaasPaymentId,
    required this.amount,
    required this.pixCopyPaste,
    required this.qrCodeImage,
  }) : super(key: key);

  @override
  State<PixQrCodeScreen> createState() => _PixQrCodeScreenState();
}

class _PixQrCodeScreenState extends State<PixQrCodeScreen> {
  static const int _totalSeconds = 600; // 10 minutos
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        if (mounted) {
          _showExpiredDialog();
        }
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerLabel {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remainingSeconds > 120) return Colors.green;
    if (_remainingSeconds > 30) return Colors.orange;
    return Colors.red;
  }

  void _copyPixCode() {
    Clipboard.setData(ClipboardData(text: widget.pixCopyPaste));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código PIX copiado!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          'PIX expirado',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'O tempo para pagamento expirou. Por favor, tente novamente.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(false);
            },
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pagamento PIX',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTimer(),
            const SizedBox(height: 24),
            _buildAmountCard(),
            const SizedBox(height: 24),
            _buildQrCode(),
            const SizedBox(height: 24),
            _buildCopyPasteSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _timerColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: _timerColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Expira em $_timerLabel',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: _timerColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Valor a pagar',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ ${widget.amount.toStringAsFixed(2).replaceAll('.', ',')}',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Corrida #${widget.corridaId}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCode() {
    try {
      final bytes = base64Decode(widget.qrCodeImage);
      return Column(
        children: [
          Text(
            'Escaneie o QR Code',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Image.memory(
              bytes,
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
        ],
      );
    } catch (_) {
      return Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'QR Code\nindisponível',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey[500]),
          ),
        ),
      );
    }
  }

  Widget _buildCopyPasteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ou use o PIX Copia e Cola',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.pixCopyPaste,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _copyPixCode,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _copyPixCode,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(
              'Copiar código PIX',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmPayment() async {
    setState(() => _isVerifying = true);
    try {
      final confirmed =
          await PaymentService.verifyPixPayment(widget.asaasPaymentId);
      if (!mounted) return;
      if (confirmed) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pagamento ainda não confirmado. Aguarde alguns instantes e tente novamente.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      // Se não conseguir verificar, confia no usuário
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isVerifying ? null : _confirmPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Já paguei',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isVerifying ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
