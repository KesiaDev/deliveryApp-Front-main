import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import 'payment_review_screen.dart';

/// Tela de seleção de método de pagamento isolada
class PaymentMethodSelectionScreen extends StatefulWidget {
  final String corridaId;
  final double amount;
  final String? description;

  const PaymentMethodSelectionScreen({
    Key? key,
    required this.corridaId,
    required this.amount,
    this.description,
  }) : super(key: key);

  @override
  State<PaymentMethodSelectionScreen> createState() =>
      _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState
    extends State<PaymentMethodSelectionScreen> {
  PaymentMethod? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forma de Pagamento',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAmountCard(),
                const SizedBox(height: 24),
                _buildMethodList(),
              ],
            ),
          ),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Valor Total',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ ${widget.amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodList() {
    final methods = [
      PaymentMethod.pix,
      PaymentMethod.creditCard,
      PaymentMethod.debitCard,
      PaymentMethod.boleto,
      PaymentMethod.cash,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione a forma de pagamento',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...methods.map((method) => _buildMethodTile(method)),
      ],
    );
  }

  Widget _buildMethodTile(PaymentMethod method) {
    final isSelected = _selectedMethod == method;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFFE53935) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Text(
          method.icon,
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(
          method.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFFE53935))
            : const Icon(Icons.radio_button_unchecked),
        onTap: () {
          setState(() {
            _selectedMethod = method;
          });
        },
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _selectedMethod == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentReviewScreen(
                          corridaId: widget.corridaId,
                          amount: widget.amount,
                          method: _selectedMethod!,
                          description: widget.description,
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Continuar',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}





