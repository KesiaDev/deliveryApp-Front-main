import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dialog para cancelamento de corrida com motivo obrigatório
class CancelCorridaDialog extends StatefulWidget {
  final String corridaId;
  final String? tituloCorrida;

  const CancelCorridaDialog({
    Key? key,
    required this.corridaId,
    this.tituloCorrida,
  }) : super(key: key);

  /// Mostra o dialog e retorna o motivo do cancelamento ou null se cancelado
  static Future<String?> show(
    BuildContext context, {
    required String corridaId,
    String? tituloCorrida,
  }) async {
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CancelCorridaDialog(
        corridaId: corridaId,
        tituloCorrida: tituloCorrida,
      ),
    );
  }

  @override
  State<CancelCorridaDialog> createState() => _CancelCorridaDialogState();
}

class _CancelCorridaDialogState extends State<CancelCorridaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  String? _motivoSelecionado;
  bool _motivoCustomizado = false;

  // Motivos pré-definidos
  final List<String> _motivosPredefinidos = [
    'Cliente não estava no local',
    'Endereço incorreto',
    'Problema com o pedido',
    'Cliente cancelou',
    'Motorista não conseguiu chegar',
    'Problema técnico',
    'Outro motivo',
  ];

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  void _onMotivoSelecionado(String? motivo) {
    setState(() {
      _motivoSelecionado = motivo;
      _motivoCustomizado = motivo == 'Outro motivo';
      if (!_motivoCustomizado) {
        _motivoController.clear();
      }
    });
  }

  void _confirmar() {
    if (_formKey.currentState!.validate()) {
      String motivoFinal;
      if (_motivoCustomizado) {
        motivoFinal = _motivoController.text.trim();
      } else {
        motivoFinal = _motivoSelecionado ?? '';
      }
      Navigator.of(context).pop(motivoFinal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cancelar Corrida',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.tituloCorrida != null) ...[
                Text(
                  'Corrida: ${widget.tituloCorrida}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16),
              ],
              Text(
                'Selecione o motivo do cancelamento:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              ..._motivosPredefinidos.map((motivo) {
                return RadioListTile<String>(
                  title: Text(
                    motivo,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  value: motivo,
                  groupValue: _motivoSelecionado,
                  onChanged: _onMotivoSelecionado,
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                );
              }),
              if (_motivoCustomizado) ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _motivoController,
                  decoration: InputDecoration(
                    labelText: 'Descreva o motivo',
                    hintText: 'Digite o motivo do cancelamento',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                  maxLength: 200,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, descreva o motivo do cancelamento';
                    }
                    if (value.trim().length < 10) {
                      return 'O motivo deve ter pelo menos 10 caracteres';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Voltar',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Confirmar Cancelamento',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
