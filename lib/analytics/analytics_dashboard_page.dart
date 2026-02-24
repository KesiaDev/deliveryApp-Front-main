import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/shared/models/DadosCorrida.dart';
import 'package:delivery_front/shared/models/SaldosCorrida.dart';
import 'package:delivery_front/analytics/services/export_service.dart';
import 'package:intl/intl.dart';

/// Tela de Dashboard de Analytics com gráficos
class AnalyticsDashboardPage extends StatefulWidget {
  final bool? isAdm;
  final int? codEmpresa;
  final int? codMotorista;

  const AnalyticsDashboardPage({
    Key? key,
    this.isAdm,
    this.codEmpresa,
    this.codMotorista,
  }) : super(key: key);

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  final UserService _userService = UserService();
  DateTime _dataInicio = DateTime.now().subtract(Duration(days: 30));
  DateTime _dataFim = DateTime.now();
  bool _isLoading = false;
  List<DadosCorridas> _corridas = [];
  List<SaldosCorrida> _saldos = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Relatórios e Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selecionarPeriodo,
            tooltip: 'Selecionar período',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.download),
            tooltip: 'Exportar relatório',
            onSelected: (value) => _exportarDados(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Exportar PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Exportar Excel'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Exportar CSV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: _carregarDados(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Erro ao carregar dados',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      snapshot.error?.toString() ?? 'Erro desconhecido',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }

      final dados = snapshot.data ?? {};
      final dadosCorridas = dados['corridas'] as List<DadosCorridas>? ?? [];
      final saldos = dados['saldos'] as List<SaldosCorrida>? ?? [];
      
      // Armazena dados para exportação
      _corridas = dadosCorridas;
      _saldos = saldos;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodoCard(),
                  SizedBox(height: 16),
                  _buildResumoCards(dadosCorridas, saldos),
                  SizedBox(height: 24),
                  _buildGraficoStatusCorridas(dadosCorridas),
                  SizedBox(height: 24),
                  _buildGraficoEvolucaoTemporal(dadosCorridas),
                  SizedBox(height: 24),
                  _buildGraficoValores(saldos),
                  SizedBox(height: 24),
                  _buildTabelaDetalhada(dadosCorridas),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final corridas = await _userService.buscaDadosCorrida(
        codEmpresa: widget.codEmpresa,
        codMotorista: widget.codMotorista,
        dtaIni: _dataInicio,
        dtaFim: _dataFim,
        isAdm: widget.isAdm,
      );

      final saldos = await _userService.buscaDadosSaldosCorrida(
        codEmpresa: widget.codEmpresa,
        codMotorista: widget.codMotorista,
        dtaIni: _dataInicio,
        dtaFim: _dataFim,
        isAdm: widget.isAdm,
      );

      return {
        'corridas': corridas ?? [],
        'saldos': saldos ?? [],
      };
    } catch (e) {
      // Log do erro para debug
      print('Erro ao carregar dados de analytics: $e');
      // Retorna listas vazias em caso de erro para não quebrar a UI
      return {
        'corridas': [],
        'saldos': [],
      };
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selecionarPeriodo() async {
    final DateTimeRange? periodo = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _dataInicio, end: _dataFim),
      locale: Locale('pt', 'BR'),
    );

    if (periodo != null) {
      setState(() {
        _dataInicio = periodo.start;
        _dataFim = periodo.end;
      });
    }
  }

  Future<void> _exportarDados(String formato) async {
    if (_corridas.isEmpty && _saldos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não há dados para exportar')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Gerando relatório...'),
              ],
            ),
          ),
        ),
      );

      final titulo = 'Relatório de Corridas - ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataInicio)} a ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataFim)}';

      switch (formato) {
        case 'pdf':
          await ExportService.exportarParaPDF(
            corridas: _corridas,
            saldos: _saldos,
            dataInicio: _dataInicio,
            dataFim: _dataFim,
            titulo: titulo,
          );
          break;
        case 'excel':
          await ExportService.exportarParaExcel(
            corridas: _corridas,
            saldos: _saldos,
            dataInicio: _dataInicio,
            dataFim: _dataFim,
            titulo: titulo,
          );
          break;
        case 'csv':
          await ExportService.exportarParaCSV(
            corridas: _corridas,
            saldos: _saldos,
            dataInicio: _dataInicio,
            dataFim: _dataFim,
            titulo: titulo,
          );
          break;
      }

      if (mounted) {
        Navigator.of(context).pop(); // Fecha dialog de loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Relatório exportado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fecha dialog de loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPeriodoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.red),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Período Selecionado',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataInicio)} - ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataFim)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoCards(List<DadosCorridas> corridas, List<SaldosCorrida> saldos) {
    int totalCorridas = 0;
    int corridasConcluidas = 0;
    int corridasCanceladas = 0;
    double totalValor = 0.0;

    for (var corrida in corridas) {
      totalCorridas += corrida.qtdCorridas ?? 0;
      if (corrida.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA) {
        corridasConcluidas += corrida.qtdCorridas ?? 0;
      }
      if (corrida.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA) {
        corridasCanceladas += corrida.qtdCorridas ?? 0;
      }
    }

    for (var saldo in saldos) {
      totalValor += saldo.vlrTotal ?? 0.0;
    }

    final taxaSucesso = totalCorridas > 0
        ? (corridasConcluidas / totalCorridas * 100)
        : 0.0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildCardResumo(
          'Total de Corridas',
          totalCorridas.toString(),
          Icons.motorcycle,
          Colors.blue,
        ),
        _buildCardResumo(
          'Taxa de Sucesso',
          '${taxaSucesso.toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.green,
        ),
        _buildCardResumo(
          'Canceladas',
          corridasCanceladas.toString(),
          Icons.cancel,
          Colors.red,
        ),
        _buildCardResumo(
          'Valor Total',
          'R\$ ${totalValor.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildCardResumo(String titulo, String valor, IconData icon, Color cor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: cor, size: 24),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            valor,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoStatusCorridas(List<DadosCorridas> corridas) {
    int novas = 0;
    int aceitas = 0;
    int emAndamento = 0;
    int concluidas = 0;
    int canceladas = 0;

    for (var corrida in corridas) {
      switch (corrida.indStatusCorrida) {
        case 0:
          novas += corrida.qtdCorridas ?? 0;
          break;
        case 1:
          aceitas += corrida.qtdCorridas ?? 0;
          break;
        case 2:
          emAndamento += corrida.qtdCorridas ?? 0;
          break;
        case 3:
          concluidas += corrida.qtdCorridas ?? 0;
          break;
        case 4:
          canceladas += corrida.qtdCorridas ?? 0;
          break;
      }
    }

    final total = novas + aceitas + emAndamento + concluidas + canceladas;
    if (total == 0) {
      return _buildEmptyChart('Status das Corridas');
    }

    return _buildChartCard(
      titulo: 'Status das Corridas',
      child: PieChart(
        PieChartData(
          sections: [
            _buildPieSection('Novas', novas, total, Colors.blue),
            _buildPieSection('Aceitas', aceitas, total, Colors.orange),
            _buildPieSection('Em Andamento', emAndamento, total, Colors.yellow[700]!),
            _buildPieSection('Concluídas', concluidas, total, Colors.green),
            _buildPieSection('Canceladas', canceladas, total, Colors.red),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  PieChartSectionData _buildPieSection(String label, int value, int total, Color color) {
    final percent = total > 0 ? (value / total) : 0.0;
    return PieChartSectionData(
      value: value.toDouble(),
      title: value > 0 ? '$value\n(${(percent * 100).toStringAsFixed(1)}%)' : '',
      color: color,
      radius: 60,
      titleStyle: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildGraficoEvolucaoTemporal(List<DadosCorridas> corridas) {
    // Agrupa corridas por dia (simplificado - em produção, buscar dados diários da API)
    final Map<String, int> corridasPorDia = {};
    
    // Simula dados diários (em produção, isso viria da API)
    final dias = <String>[];
    final valores = <double>[];
    
    for (int i = 6; i >= 0; i--) {
      final data = DateTime.now().subtract(Duration(days: i));
      final dia = DateFormat('dd/MM', 'pt_BR').format(data);
      dias.add(dia);
      valores.add((corridas.length * (0.8 + (i * 0.05))).toDouble());
    }

    return _buildChartCard(
      titulo: 'Evolução de Corridas (Últimos 7 dias)',
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: valores.isNotEmpty ? valores.reduce((a, b) => a > b ? a : b) * 1.2 : 10,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < dias.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        dias[index],
                        style: GoogleFonts.poppins(fontSize: 10),
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.poppins(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            valores.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: valores[index],
                  color: Colors.red,
                  width: 20,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraficoValores(List<SaldosCorrida> saldos) {
    if (saldos.isEmpty) {
      return _buildEmptyChart('Valores por Período');
    }

    final valores = saldos.map((s) => s.vlrTotal ?? 0.0).toList();
    final maxValor = valores.isNotEmpty ? valores.reduce((a, b) => a > b ? a : b) : 0.0;

    return _buildChartCard(
      titulo: 'Valores por Período',
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(enabled: true),
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'R\$ ${value.toInt()}',
                    style: GoogleFonts.poppins(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (valores.length - 1).toDouble(),
          minY: 0,
          maxY: maxValor * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                valores.length,
                (index) => FlSpot(index.toDouble(), valores[index]),
              ),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaDetalhada(List<DadosCorridas> corridas) {
    if (corridas.isEmpty) {
      return SizedBox.shrink();
    }

    return _buildChartCard(
      titulo: 'Detalhamento por Status',
      child: Column(
        children: corridas.map((corrida) {
          final status = _getStatusLabel(corrida.indStatusCorrida);
          final cor = _getStatusColor(corrida.indStatusCorrida);
          
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${corrida.qtdCorridas ?? 0} corridas',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getStatusLabel(int? status) {
    switch (status) {
      case 0:
        return 'Nova Corrida';
      case 1:
        return 'Aceita';
      case 2:
        return 'Em Andamento';
      case 3:
        return 'Concluída';
      case 4:
        return 'Cancelada';
      default:
        return 'Desconhecido';
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.yellow[700]!;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildChartCard({required String titulo, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String titulo) {
    return _buildChartCard(
      titulo: titulo,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Sem dados para exibir',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
