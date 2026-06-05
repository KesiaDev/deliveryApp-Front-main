import 'dart:io';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/modules/payments/models/empresa_payment_config.dart';
import 'package:delivery_front/modules/payments/services/empresa_payment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tela de boletos semanais — empresa vê suas faturas
/// Admin vê todas as faturas pendentes de todas as empresas
class WeeklyInvoicesScreen extends StatelessWidget {
  final int? codEmpresa; // null = admin (vê todas)
  final bool isAdmin;

  const WeeklyInvoicesScreen({
    Key? key,
    this.codEmpresa,
    this.isAdmin = false,
  }) : super(key: key);

  static const _red = Color(0xFFE53935);
  static const _bg = Color(0xFFF7F5FA);
  static const _card = Colors.white;
  static const _text = Color(0xFF1A1A1A);
  static const _sub = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final stream = isAdmin
        ? EmpresaPaymentService.streamAllPendingInvoices()
        : EmpresaPaymentService.streamInvoices(codEmpresa!);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Boletos Pendentes' : 'Boletos Semanais',
          style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w600, color: _text),
        ),
        backgroundColor: _card,
        elevation: 0,
        iconTheme: const IconThemeData(color: _text),
      ),
      body: StreamBuilder<List<WeeklyInvoice>>(
        stream: stream,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final invoices = snap.data!;
          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 56, color: Colors.green),
                  const SizedBox(height: 12),
                  Text(
                    isAdmin
                        ? 'Nenhum boleto pendente!'
                        : 'Nenhum boleto gerado ainda.',
                    style: GoogleFonts.poppins(fontSize: 15, color: _sub),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _InvoiceCard(
              invoice: invoices[i],
              isAdmin: isAdmin,
              adminName: ApiBaseHelper.userSessao?.desNome ?? 'Admin',
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceCard extends StatefulWidget {
  final WeeklyInvoice invoice;
  final bool isAdmin;
  final String adminName;

  const _InvoiceCard({
    required this.invoice,
    required this.isAdmin,
    required this.adminName,
  });

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  bool _uploading = false;

  Color get _statusColor {
    switch (widget.invoice.status) {
      case 'paid': return Colors.green;
      case 'overdue': return Colors.red.shade700;
      case 'unlocked': return Colors.blue;
      case 'cancelled': return Colors.grey;
      default: return Colors.orange;
    }
  }

  Future<void> _uploadProof() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      // Simples: salva URL local como placeholder
      // Em produção: fazer upload para Firebase Storage
      final proofUrl = 'local:${picked.path}';

      if (widget.isAdmin) {
        await EmpresaPaymentService.unlockAfterProof(
          invoiceId: widget.invoice.id,
          codEmpresa: widget.invoice.codEmpresa,
          adminName: widget.adminName,
          proofUrl: proofUrl,
        );
      } else {
        // Empresa envia comprovante → aguarda admin verificar
        await EmpresaPaymentService.markInvoicePaid(
          widget.invoice.id,
          proofUrl: proofUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isAdmin
                ? 'Empresa desbloqueada!'
                : 'Comprovante enviado! Aguardando confirmação do admin.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openBoleto() async {
    final url = widget.invoice.boletoUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL do boleto não disponível')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final fmt = DateFormat('dd/MM/yyyy');
    final fmtCurr = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: inv.isOverdue
            ? Border.all(color: Colors.red.shade300, width: 1.5)
            : null,
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho: empresa + status
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isAdmin)
                    Text(inv.empresaName,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A))),
                  Text(
                    'Semana ${fmt.format(inv.weekStart)} → ${fmt.format(inv.weekEnd)}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: const Color(0xFF757575)),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                inv.statusLabel,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor),
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // Valor + corridas
          Row(children: [
            _statChip(
              Icons.attach_money_rounded,
              fmtCurr.format(inv.totalValue),
              Colors.green,
            ),
            const SizedBox(width: 8),
            _statChip(
              Icons.motorcycle_rounded,
              '${inv.corridaCount} corridas',
              const Color(0xFFE53935),
            ),
          ]),

          const SizedBox(height: 10),

          // Vencimento
          Row(children: [
            Icon(
              Icons.event_rounded,
              size: 15,
              color: inv.isOverdue ? Colors.red : const Color(0xFF757575),
            ),
            const SizedBox(width: 4),
            Text(
              'Vencimento: ${fmt.format(inv.dueDate)}',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: inv.isOverdue
                      ? Colors.red.shade700
                      : const Color(0xFF757575),
                  fontWeight:
                      inv.isOverdue ? FontWeight.w600 : FontWeight.normal),
            ),
          ]),

          // Código de barras
          if (inv.boletoBarCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(
                    inv.boletoBarCode!,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inv.boletoBarCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Código copiado!'),
                          backgroundColor: Colors.green),
                    );
                  },
                ),
              ]),
            ),
          ],

          const SizedBox(height: 12),

          // Ações
          if (!inv.isPaid && !inv.isUnlocked) ...[
            Row(children: [
              if (inv.boletoUrl != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openBoleto,
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text('Ver boleto',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(color: Color(0xFFE53935)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              if (inv.boletoUrl != null) const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _uploadProof,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_rounded, size: 16),
                  label: Text(
                    widget.isAdmin
                        ? 'Verificar e desbloquear'
                        : 'Enviar comprovante',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isAdmin ? Colors.green : const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ]),
          ],

          if (inv.isPaid || inv.isUnlocked) ...[
            Row(children: [
              Icon(
                inv.isPaid
                    ? Icons.check_circle_rounded
                    : Icons.verified_rounded,
                color: Colors.green,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                inv.isPaid
                    ? 'Pago em ${fmt.format(inv.paidAt!)}'
                    : 'Desbloqueado por ${inv.unlockedBy ?? 'admin'}',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
