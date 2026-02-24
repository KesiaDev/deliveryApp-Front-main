import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Widget para seleção de data/hora agendada para corrida
class AgendamentoCorridaWidget extends StatefulWidget {
  final DateTime? dataAgendamentoInicial;
  final Function(DateTime?) onDataSelecionada;
  final bool enabled;

  const AgendamentoCorridaWidget({
    Key? key,
    this.dataAgendamentoInicial,
    required this.onDataSelecionada,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<AgendamentoCorridaWidget> createState() => _AgendamentoCorridaWidgetState();
}

class _AgendamentoCorridaWidgetState extends State<AgendamentoCorridaWidget> {
  bool _isAgendada = false;
  DateTime? _dataAgendamento;
  TimeOfDay? _horaAgendamento;

  @override
  void initState() {
    super.initState();
    _dataAgendamento = widget.dataAgendamentoInicial;
    if (_dataAgendamento != null) {
      _isAgendada = true;
      _horaAgendamento = TimeOfDay.fromDateTime(_dataAgendamento!);
    }
  }

  Future<void> _selecionarData() async {
    final DateTime agora = DateTime.now();
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: _dataAgendamento ?? agora.add(Duration(days: 1)),
      firstDate: agora,
      lastDate: agora.add(Duration(days: 365)),
      locale: Locale('pt', 'BR'),
      helpText: 'Selecione a data',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dataSelecionada != null) {
      setState(() {
        _dataAgendamento = dataSelecionada;
        _atualizarDataHora();
      });
    }
  }

  Future<void> _selecionarHora() async {
    final TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: _horaAgendamento ?? TimeOfDay.now(),
      helpText: 'Selecione a hora',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (horaSelecionada != null) {
      setState(() {
        _horaAgendamento = horaSelecionada;
        _atualizarDataHora();
      });
    }
  }

  void _atualizarDataHora() {
    if (_dataAgendamento != null && _horaAgendamento != null) {
      final DateTime dataHoraCompleta = DateTime(
        _dataAgendamento!.year,
        _dataAgendamento!.month,
        _dataAgendamento!.day,
        _horaAgendamento!.hour,
        _horaAgendamento!.minute,
      );
      widget.onDataSelecionada(dataHoraCompleta);
    } else {
      widget.onDataSelecionada(null);
    }
  }

  String _formatarDataHora() {
    if (_dataAgendamento != null && _horaAgendamento != null) {
      final DateTime dataHoraCompleta = DateTime(
        _dataAgendamento!.year,
        _dataAgendamento!.month,
        _dataAgendamento!.day,
        _horaAgendamento!.hour,
        _horaAgendamento!.minute,
      );
      return DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(dataHoraCompleta);
    }
    return 'Não selecionado';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isAgendada ? Colors.red.withOpacity(0.3) : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: _isAgendada ? Colors.red : Colors.grey[600],
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Corrida Agendada',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isAgendada ? Colors.black87 : Colors.grey[700],
                ),
              ),
              Spacer(),
              Switch(
                value: _isAgendada,
                onChanged: widget.enabled
                    ? (value) {
                        setState(() {
                          _isAgendada = value;
                          if (!value) {
                            _dataAgendamento = null;
                            _horaAgendamento = null;
                            widget.onDataSelecionada(null);
                          }
                        });
                      }
                    : null,
                activeColor: Colors.red,
              ),
            ],
          ),
          if (_isAgendada) ...[
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.enabled ? _selecionarData : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  _dataAgendamento != null
                                      ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataAgendamento!)
                                      : 'Selecione a data',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: widget.enabled && _dataAgendamento != null ? _selecionarHora : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hora',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  _horaAgendamento != null
                                      ? _horaAgendamento!.format(context)
                                      : 'Selecione a hora',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_dataAgendamento != null && _horaAgendamento != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Agendada para: ${_formatarDataHora()}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
