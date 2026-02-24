import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

/// Tela de revisão e confirmação de pagamento isolada
class PaymentReviewScreen extends StatefulWidget {
  final String corridaId;
  final double amount;
  final PaymentMethod method;
  final String? description;

  const PaymentReviewScreen({
    Key? key,
    required this.corridaId,
    required this.amount,
    required this.method,
    this.description,
  }) : super(key: key);

  @override
  State<PaymentReviewScreen> createState() => _PaymentReviewScreenState();
}

class _PaymentReviewScreenState extends State<PaymentReviewScreen> {
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final request = PaymentRequest(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        corridaId: widget.corridaId,
        amount: widget.amount,
        method: widget.method,
        description: widget.description,
      );

      final response = await PaymentService.processPayment(request);

      if (mounted) {
        if (response.success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pagamento processado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.errorMessage ?? 'Erro ao processar pagamento'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Revisar Pagamento',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildMethodInfo(),
            const SizedBox(height: 32),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo do Pagamento',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              Text(
                'R\$ ${widget.amount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (widget.description != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Descrição',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                Expanded(
                  child: Text(
                    widget.description!,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            widget.method.icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forma de Pagamento',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.method.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Confirmar Pagamento',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}





