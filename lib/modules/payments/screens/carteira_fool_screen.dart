import 'package:delivery_front/modules/payments/models/empresa_payment_config.dart';
import 'package:delivery_front/modules/payments/services/empresa_payment_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Tela da Carteira Fool — visão empresa
/// Mostra saldo atual, extrato de transações e histórico
class CarteiraFoolScreen extends StatelessWidget {
  final int codEmpresa;
  final String empresaName;

  const CarteiraFoolScreen({
    Key? key,
    required this.codEmpresa,
    required this.empresaName,
  }) : super(key: key);

  static const _red = Color(0xFFE53935);
  static const _bg = Color(0xFFF7F5FA);
  static const _card = Colors.white;
  static const _text = Color(0xFF1A1A1A);
  static const _sub = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'Carteira Fool',
          style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w600, color: _text),
        ),
        backgroundColor: _card,
        elevation: 0,
        iconTheme: const IconThemeData(color: _text),
      ),
      body: Column(
        children: [
          // ── Saldo ─────────────────────────────────────────────────
          StreamBuilder<double>(
            stream: EmpresaPaymentService.streamWalletBalance(codEmpresa),
            builder: (_, snap) {
              final balance = snap.data ?? 0.0;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: balance > 0
                        ? [const Color(0xFF43A047), const Color(0xFF66BB6A)]
                        : [Colors.grey.shade500, Colors.grey.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: (balance > 0 ? Colors.green : Colors.grey)
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text('Carteira Fool',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500)),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                      'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      empresaName,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.white70),
                    ),
                    if (balance <= 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Saldo insuficiente — solicite crédito ao admin',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          // ── Extrato ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Icon(Icons.receipt_long_rounded, size: 18, color: _sub),
              const SizedBox(width: 6),
              Text('Extrato',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
            ]),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<List<WalletTransaction>>(
              stream:
                  EmpresaPaymentService.streamWalletTransactions(codEmpresa),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final txs = snap.data!;
                if (txs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_rounded,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text('Nenhuma transação ainda',
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: _sub)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: txs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _TxTile(tx: txs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final WalletTransaction tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.isCredit;
    final color = isCredit ? Colors.green : Colors.red.shade700;
    final sign = isCredit ? '+' : '-';
    final fmt = DateFormat('dd/MM HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCredit
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tx.description,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A1A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(
                fmt.format(tx.createdAt),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: const Color(0xFF757575)),
              ),
            ],
          ),
        ),
        Text(
          '$sign R\$ ${tx.amount.toStringAsFixed(2).replaceAll('.', ',')}',
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color),
        ),
      ]),
    );
  }
}
