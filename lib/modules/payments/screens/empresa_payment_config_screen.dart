import 'package:delivery_front/modules/payments/models/empresa_payment_config.dart';
import 'package:delivery_front/modules/payments/services/empresa_payment_service.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tela admin: configura quais métodos de pagamento a empresa aceita,
/// edita endereço, gerencia bloqueio e créditos na Carteira Fool.
class EmpresaPaymentConfigScreen extends StatefulWidget {
  final Empresa empresa;
  final String adminName;

  const EmpresaPaymentConfigScreen({
    Key? key,
    required this.empresa,
    required this.adminName,
  }) : super(key: key);

  @override
  State<EmpresaPaymentConfigScreen> createState() =>
      _EmpresaPaymentConfigScreenState();
}

class _EmpresaPaymentConfigScreenState
    extends State<EmpresaPaymentConfigScreen> {
  static const _red = Color(0xFFE53935);
  static const _bg = Color(0xFFF7F5FA);
  static const _card = Colors.white;
  static const _text = Color(0xFF1A1A1A);
  static const _sub = Color(0xFF757575);

  EmpresaPaymentConfig? _config;
  double _walletBalance = 0.0;
  bool _loading = true;
  bool _saving = false;

  // Cópia editável dos métodos
  late Set<EmpresaPayMethod> _selectedMethods;

  // Adicionar crédito
  final _creditCtrl = TextEditingController();
  final _creditDescCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _creditCtrl.dispose();
    _creditDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cod = widget.empresa.codEmpresa ?? 0;
    final cfg = await EmpresaPaymentService.getConfig(cod);
    final bal = await EmpresaPaymentService.getWalletBalance(cod);
    if (mounted) {
      setState(() {
        _config = cfg;
        _walletBalance = bal;
        _selectedMethods = cfg.acceptedMethods.toSet();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_config == null) return;
    setState(() => _saving = true);
    try {
      final updated = _config!.copyWith(
        acceptedMethods: _selectedMethods.toList(),
        updatedBy: widget.adminName,
      );
      await EmpresaPaymentService.saveConfig(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _config = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleBlock() async {
    if (_config == null) return;
    final cod = widget.empresa.codEmpresa ?? 0;
    final isBlocked = _config!.isBlocked;

    if (isBlocked) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Desbloquear empresa'),
          content: Text(
              'Desbloquear ${widget.empresa.desNomeFantasia ?? 'empresa'}?\nMotivo do bloqueio: ${_config!.blockReason ?? '—'}'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Desbloquear')),
          ],
        ),
      );
      if (confirm != true) return;
      await EmpresaPaymentService.unblockEmpresa(cod, widget.adminName);
    } else {
      final motivoCtrl = TextEditingController();
      final motivo = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Bloquear empresa'),
          content: TextField(
            controller: motivoCtrl,
            decoration: const InputDecoration(labelText: 'Motivo do bloqueio'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, motivoCtrl.text),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Bloquear')),
          ],
        ),
      );
      if (motivo == null || motivo.isEmpty) return;
      await EmpresaPaymentService.blockEmpresa(cod, motivo, widget.adminName);
    }

    await _load();
  }

  Future<void> _addCredit() async {
    final amount = double.tryParse(
        _creditCtrl.text.replaceAll(',', '.').trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um valor válido')));
      return;
    }
    final desc = _creditDescCtrl.text.trim().isEmpty
        ? 'Crédito adicionado pelo admin'
        : _creditDescCtrl.text.trim();

    await EmpresaPaymentService.addWalletCredit(
      codEmpresa: widget.empresa.codEmpresa ?? 0,
      amount: amount,
      description: desc,
      adminName: widget.adminName,
    );

    _creditCtrl.clear();
    _creditDescCtrl.clear();

    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('R\$ ${amount.toStringAsFixed(2)} adicionado à Carteira Fool!'),
        backgroundColor: Colors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final empresa = widget.empresa;
    final nomeEmpresa =
        empresa.desNomeFantasia ?? empresa.desRazaoSocial ?? 'Empresa';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'Config. Pagamentos',
          style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w600, color: _text),
        ),
        backgroundColor: _card,
        elevation: 0,
        iconTheme: const IconThemeData(color: _text),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Salvar',
                      style: GoogleFonts.poppins(
                          color: _red, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info da empresa ──────────────────────────────────
                  _sectionCard(
                    icon: Icons.business_rounded,
                    title: nomeEmpresa,
                    children: [
                      if (empresa.desCpfCnpj != null)
                        _infoRow(Icons.badge_rounded, 'CNPJ/CPF',
                            empresa.desCpfCnpj!),
                      if (empresa.enderecos?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        _infoRow(
                          Icons.location_on_rounded,
                          'Endereço',
                          _formatEndereco(empresa.enderecos!.first),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Status de bloqueio ───────────────────────────────
                  _BlockStatusCard(
                    config: _config!,
                    onToggle: _toggleBlock,
                  ),
                  const SizedBox(height: 12),

                  // ── Métodos aceitos ──────────────────────────────────
                  _sectionCard(
                    icon: Icons.payment_rounded,
                    title: 'Métodos de pagamento aceitos',
                    children: EmpresaPayMethod.values
                        .map((m) => _MethodTile(
                              method: m,
                              selected: _selectedMethods.contains(m),
                              onChanged: (v) => setState(() {
                                if (v) {
                                  _selectedMethods.add(m);
                                } else {
                                  _selectedMethods.remove(m);
                                }
                              }),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // ── Carteira Fool ────────────────────────────────────
                  _sectionCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Carteira Fool',
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.savings_rounded,
                              color: Colors.green, size: 28),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Saldo atual',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: _sub)),
                              Text(
                                'R\$ ${_walletBalance.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _walletBalance > 0 ? Colors.green : _sub,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Adicionar crédito',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _text)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _creditCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDecor('R\$ Valor (ex: 50,00)'),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _creditDescCtrl,
                            decoration: _inputDecor('Descrição (opcional)'),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addCredit,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text('Adicionar crédito',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionCard(
      {required IconData icon,
      required String title,
      required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _red, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
          ]),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: _sub),
        const SizedBox(width: 6),
        Text('$label: ',
            style: GoogleFonts.poppins(fontSize: 12, color: _sub)),
        Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 12, color: _text),
                overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: _sub),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      );

  String _formatEndereco(dynamic e) {
    final parts = <String>[];
    if (e.desRua?.isNotEmpty == true) parts.add(e.desRua);
    if (e.desNumero?.isNotEmpty == true) parts.add(e.desNumero);
    if (e.desBairro?.isNotEmpty == true) parts.add(e.desBairro);
    if (e.desCidade?.isNotEmpty == true) parts.add(e.desCidade);
    if (e.desEstado?.isNotEmpty == true) parts.add(e.desEstado);
    return parts.join(', ');
  }
}

class _BlockStatusCard extends StatelessWidget {
  final EmpresaPaymentConfig config;
  final VoidCallback onToggle;

  const _BlockStatusCard({required this.config, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isBlocked = config.isBlocked;
    final color = isBlocked ? Colors.red.shade700 : Colors.green;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(
          isBlocked ? Icons.lock_rounded : Icons.lock_open_rounded,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBlocked ? '🔒 Empresa bloqueada' : '✅ Empresa ativa',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
              if (isBlocked && config.blockReason != null)
                Text(
                  config.blockReason!,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade900),
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: onToggle,
          style:
              TextButton.styleFrom(foregroundColor: isBlocked ? Colors.green : Colors.red),
          child: Text(
            isBlocked ? 'Desbloquear' : 'Bloquear',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final EmpresaPayMethod method;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _MethodTile(
      {required this.method,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!selected),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(method.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(method.label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF1A1A1A))),
          ),
          Switch(
            value: selected,
            onChanged: onChanged,
            activeColor: const Color(0xFFE53935),
          ),
        ]),
      ),
    );
  }
}
