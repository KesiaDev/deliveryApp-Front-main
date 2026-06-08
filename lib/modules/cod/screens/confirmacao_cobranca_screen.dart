import 'dart:async';
import 'package:delivery_front/modules/cod/models/cod_model.dart';
import 'package:delivery_front/modules/cod/services/cod_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Tela onde o motorista confirma quanto recebeu do cliente final
/// Aberta automaticamente ao encerrar uma corrida CoD
class ConfirmacaoCobrancaScreen extends StatefulWidget {
  final int numSeq;
  final CodDelivery cod;
  final int codMotorista;

  const ConfirmacaoCobrancaScreen({
    Key? key,
    required this.numSeq,
    required this.cod,
    required this.codMotorista,
  }) : super(key: key);

  @override
  State<ConfirmacaoCobrancaScreen> createState() =>
      _ConfirmacaoCobrancaScreenState();
}

class _ConfirmacaoCobrancaScreenState
    extends State<ConfirmacaoCobrancaScreen> {
  static const _red = Color(0xFFE53935);
  static const _green = Color(0xFF43A047);

  final _vlrCtrl = TextEditingController();
  TipoRecebimento _tipoSelecionado = TipoRecebimento.dinheiro;
  bool _processing = false;
  String? _errorMsg;

  late final NumberFormat _fmt;

  @override
  void initState() {
    super.initState();
    _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
    // Pre-preenche com valor total
    _vlrCtrl.text = widget.cod.vlrCobranca.toStringAsFixed(2).replaceAll('.', ',');
    if (!widget.cod.indMaquininha) {
      _tipoSelecionado = TipoRecebimento.dinheiro;
    }
  }

  @override
  void dispose() {
    _vlrCtrl.dispose();
    super.dispose();
  }

  double get _vlrInformado {
    final raw = _vlrCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(raw) ?? 0.0;
  }

  bool get _recebeuTudo => _vlrInformado >= widget.cod.vlrCobranca - 0.01;

  Future<void> _confirmar() async {
    final vlr = _vlrInformado;
    if (vlr <= 0) {
      setState(() => _errorMsg = 'Informe o valor recebido');
      return;
    }
    if (vlr > widget.cod.vlrCobranca + 0.01) {
      setState(() => _errorMsg = 'Valor maior que o esperado (${_fmt.format(widget.cod.vlrCobranca)})');
      return;
    }

    setState(() { _processing = true; _errorMsg = null; });
    try {
      final result = await CodService.confirmReceipt(
        numSeq: widget.numSeq,
        codMotorista: widget.codMotorista,
        vlrRecebido: vlr,
        tipoRecebimento: _tipoSelecionado,
      );

      if (!mounted) return;

      // Retorna true = corrida pode finalizar | false = pendência criada (ainda finaliza)
      Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) setState(() { _errorMsg = 'Erro: $e'; _processing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cod = widget.cod;
    final fmt = _fmt;

    return PopScope(
      canPop: false, // Motorista não pode fechar sem confirmar
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5FA),
        appBar: AppBar(
          title: Text(
            'Confirmar Recebimento',
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () {
                // Permite fechar sem confirmar — pendência será verificada depois
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sair sem confirmar?'),
                    content: const Text(
                      'Você ainda não confirmou o recebimento. '
                      'Uma pendência poderá ser criada automaticamente.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // fecha dialog
                          Navigator.pop(context, null); // fecha tela
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Sair mesmo assim'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Depois', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card de valor esperado ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text('Valor a cobrar do cliente',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60)),
                    const SizedBox(height: 8),
                    Text(
                      fmt.format(cod.vlrCobranca),
                      style: GoogleFonts.poppins(
                          fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    if (cod.indMaquininha) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '💳 Maquininha disponível',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text('Corrida #${widget.numSeq}',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Valor recebido ─────────────────────────────────────
              Text('Quanto você recebeu?',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              TextField(
                controller: _vlrCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                onChanged: (_) => setState(() => _errorMsg = null),
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: 'R\$ ',
                  prefixStyle: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _red, width: 2),
                  ),
                  errorText: _errorMsg,
                ),
              ),

              // Atalho — botão para preencher valor total
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() {
                    _vlrCtrl.text = cod.vlrCobranca.toStringAsFixed(2).replaceAll('.', ',');
                  }),
                  child: Text('Preencher valor total',
                      style: GoogleFonts.poppins(color: _red, fontSize: 12)),
                ),
              ),

              const SizedBox(height: 20),

              // ── Tipo de recebimento ────────────────────────────────
              Text('Como recebeu?',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 10),
              ...TipoRecebimento.values
                  .where((t) => t != TipoRecebimento.maquininha || cod.indMaquininha)
                  .map((t) => _TipoTile(
                        tipo: t,
                        selected: _tipoSelecionado == t,
                        onTap: () => setState(() => _tipoSelecionado = t),
                      )),

              const SizedBox(height: 28),

              // ── Aviso de pendência ─────────────────────────────────
              if (!_recebeuTudo) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Você terá 60 minutos para devolver '
                        '${fmt.format(cod.vlrCobranca - _vlrInformado)} '
                        'à empresa antes de ser bloqueado.',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade900),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // ── Botão confirmar ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _processing ? null : _confirmar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _recebeuTudo ? _green : _red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _processing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          _recebeuTudo
                              ? '✓ Confirmar Recebimento Total'
                              : '⚠️ Confirmar com Pendência',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipoTile extends StatelessWidget {
  final TipoRecebimento tipo;
  final bool selected;
  final VoidCallback onTap;

  const _TipoTile({required this.tipo, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const _red = Color(0xFFE53935);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _red.withOpacity(0.07) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _red : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Text(
            tipo == TipoRecebimento.dinheiro
                ? '💵'
                : tipo == TipoRecebimento.maquininha
                    ? '💳'
                    : '💵💳',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tipo.label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? _red : const Color(0xFF1A1A1A))),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: _red, size: 20),
        ]),
      ),
    );
  }
}
