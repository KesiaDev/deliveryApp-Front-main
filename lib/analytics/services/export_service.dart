import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:delivery_front/shared/models/DadosCorrida.dart';
import 'package:delivery_front/shared/models/SaldosCorrida.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:intl/intl.dart';

/// Serviço para exportação de dados em PDF, Excel e CSV
class ExportService {
  /// Exporta dados de corridas para PDF
  static Future<void> exportarParaPDF({
    required List<DadosCorridas> corridas,
    required List<SaldosCorrida> saldos,
    required DateTime dataInicio,
    required DateTime dataFim,
    String? titulo,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          // Cabeçalho
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      titulo ?? 'Relatório de Corridas',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Período: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(dataInicio)} - ${DateFormat('dd/MM/yyyy', 'pt_BR').format(dataFim)}',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red700,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'FD',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Resumo
          _buildResumoPDF(corridas, saldos),
          pw.SizedBox(height: 20),

          // Tabela de Corridas
          pw.Text(
            'Detalhamento por Status',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildTabelaCorridasPDF(corridas),
          pw.SizedBox(height: 20),

          // Tabela de Saldos
          if (saldos.isNotEmpty) ...[
            pw.Text(
              'Detalhamento de Valores',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            _buildTabelaSaldosPDF(saldos),
          ],
        ],
      ),
    );

    // Compartilhar ou salvar
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static pw.Widget _buildResumoPDF(List<DadosCorridas> corridas, List<SaldosCorrida> saldos) {
    int totalCorridas = 0;
    int concluidas = 0;
    int canceladas = 0;
    double totalValor = 0.0;

    for (var corrida in corridas) {
      totalCorridas += corrida.qtdCorridas ?? 0;
      if (corrida.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA) {
        concluidas += corrida.qtdCorridas ?? 0;
      }
      if (corrida.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA) {
        canceladas += corrida.qtdCorridas ?? 0;
      }
    }

    for (var saldo in saldos) {
      totalValor += saldo.vlrTotal ?? 0.0;
    }

    final taxaSucesso = totalCorridas > 0 ? (concluidas / totalCorridas * 100) : 0.0;

    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildCardResumoPDF('Total', totalCorridas.toString(), PdfColors.blue700),
          _buildCardResumoPDF('Taxa Sucesso', '${taxaSucesso.toStringAsFixed(1)}%', PdfColors.green700),
          _buildCardResumoPDF('Canceladas', canceladas.toString(), PdfColors.red700),
          _buildCardResumoPDF('Valor Total', 'R\$ ${totalValor.toStringAsFixed(2)}', PdfColors.orange700),
        ],
      ),
    );
  }

  static pw.Widget _buildCardResumoPDF(String titulo, String valor, PdfColor cor) {
    return pw.Column(
      children: [
        pw.Text(
          titulo,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTabelaCorridasPDF(List<DadosCorridas> corridas) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildCellPDF('Status', isHeader: true),
            _buildCellPDF('Quantidade', isHeader: true),
            _buildCellPDF('Percentual', isHeader: true),
          ],
        ),
        // Dados
        ...corridas.map((corrida) {
          final status = _getStatusLabel(corrida.indStatusCorrida);
          final qtd = corrida.qtdCorridas ?? 0;
          final total = corridas.fold<int>(0, (sum, c) => sum + (c.qtdCorridas ?? 0));
          final percent = total > 0 ? (qtd / total * 100) : 0.0;

          return pw.TableRow(
            children: [
              _buildCellPDF(status),
              _buildCellPDF(qtd.toString()),
              _buildCellPDF('${percent.toStringAsFixed(1)}%'),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTabelaSaldosPDF(List<SaldosCorrida> saldos) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildCellPDF('Valor Total', isHeader: true),
            _buildCellPDF('Valor Restaurante', isHeader: true),
            _buildCellPDF('Status Motorista', isHeader: true),
            _buildCellPDF('Status Estabelecimento', isHeader: true),
          ],
        ),
        // Dados
        ...saldos.map((saldo) {
          return pw.TableRow(
            children: [
              _buildCellPDF('R\$ ${(saldo.vlrTotal ?? 0.0).toStringAsFixed(2)}'),
              _buildCellPDF('R\$ ${(saldo.vlrTotalRestaurante ?? 0.0).toStringAsFixed(2)}'),
              _buildCellPDF(_getStatusPagamento(saldo.indStatusRecebimentoMotorista)),
              _buildCellPDF(_getStatusPagamento(saldo.indStatusPagamentoEstabelecimento)),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildCellPDF(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Exporta dados de corridas para Excel
  static Future<void> exportarParaExcel({
    required List<DadosCorridas> corridas,
    required List<SaldosCorrida> saldos,
    required DateTime dataInicio,
    required DateTime dataFim,
    String? titulo,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    final sheet = excel[titulo ?? 'Relatório'];

    // Cabeçalho
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = titulo ?? 'Relatório de Corridas';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Período: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(dataInicio)} - ${DateFormat('dd/MM/yyyy', 'pt_BR').format(dataFim)}';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = 'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(DateTime.now())}';

    int rowIndex = 4;

    // Resumo
    int totalCorridas = corridas.fold<int>(0, (sum, c) => sum + (c.qtdCorridas ?? 0));
    int concluidas = corridas
        .where((c) => c.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA)
        .fold<int>(0, (sum, c) => sum + (c.qtdCorridas ?? 0));
    int canceladas = corridas
        .where((c) => c.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA)
        .fold<int>(0, (sum, c) => sum + (c.qtdCorridas ?? 0));
    double totalValor = saldos.fold<double>(0, (sum, s) => sum + (s.vlrTotal ?? 0.0));

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Resumo';
    rowIndex++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Total de Corridas';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = totalCorridas;
    rowIndex++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Concluídas';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = concluidas;
    rowIndex++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Canceladas';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = canceladas;
    rowIndex++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Valor Total';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = totalValor;
    rowIndex += 2;

    // Tabela de Corridas
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Detalhamento por Status';
    rowIndex++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Status';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = 'Quantidade';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = 'Percentual';
    rowIndex++;

    for (var corrida in corridas) {
      final status = _getStatusLabel(corrida.indStatusCorrida);
      final qtd = corrida.qtdCorridas ?? 0;
      final percent = totalCorridas > 0 ? (qtd / totalCorridas * 100) : 0.0;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = status;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = qtd;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = '${percent.toStringAsFixed(1)}%';
      rowIndex++;
    }

    // Salvar arquivo
    final bytes = excel.save();
    if (bytes != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'relatorio_${DateFormat('yyyyMMdd_HHmmss', 'pt_BR').format(DateTime.now())}.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Relatório de Corridas - ${DateFormat('dd/MM/yyyy', 'pt_BR').format(dataInicio)} a ${DateFormat('dd/MM/yyyy', 'pt_BR').format(dataFim)}',
      );
    }
  }

  /// Exporta dados de corridas para CSV
  static Future<void> exportarParaCSV({
    required List<DadosCorridas> corridas,
    required List<SaldosCorrida> saldos,
    required DateTime dataInicio,
    required DateTime dataFim,
    String? titulo,
  }) async {
    final List<List<dynamic>> rows = [];

    // Cabeçalho
    rows.add(['Relatório de Corridas']);
    rows.add(['Período', '${DateFormat('dd/MM/yyyy', 'pt_BR').format(dataInicio)} - ${DateFormat('dd/MM/yyyy', 'pt_BR').format(dataFim)}']);
    rows.add(['Gerado em', DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(DateTime.now())]);
    rows.add([]);

    // Resumo
    int totalCorridas = corridas.fold<int>(0, (sum, c) => sum + (c.qtdCorridas ?? 0));
    int concluidas = corridas
        .where((c) => c.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA)
        .fold<int>(0, (sum, c) => sum + (c.qtdCorridas ?? 0));
    int canceladas = corridas
        .where((c) => c.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA)
        .fold<int>(0, (sum, c) => sum + (c.qtdCorridas ?? 0));
    double totalValor = saldos.fold<double>(0, (sum, s) => sum + (s.vlrTotal ?? 0.0));

    rows.add(['Resumo']);
    rows.add(['Total de Corridas', totalCorridas]);
    rows.add(['Concluídas', concluidas]);
    rows.add(['Canceladas', canceladas]);
    rows.add(['Valor Total', totalValor.toStringAsFixed(2)]);
    rows.add([]);

    // Tabela de Corridas
    rows.add(['Detalhamento por Status']);
    rows.add(['Status', 'Quantidade', 'Percentual']);

    for (var corrida in corridas) {
      final status = _getStatusLabel(corrida.indStatusCorrida);
      final qtd = corrida.qtdCorridas ?? 0;
      final percent = totalCorridas > 0 ? (qtd / totalCorridas * 100) : 0.0;
      rows.add([status, qtd, '${percent.toStringAsFixed(1)}%']);
    }

    // Converter para CSV
    final csv = const ListToCsvConverter().convert(rows);

    // Salvar arquivo
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'relatorio_${DateFormat('yyyyMMdd_HHmmss', 'pt_BR').format(DateTime.now())}.csv';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Relatório de Corridas - ${DateFormat('dd/MM/yyyy', 'pt_BR').format(dataInicio)} a ${DateFormat('dd/MM/yyyy', 'pt_BR').format(dataFim)}',
    );
  }

  static String _getStatusLabel(int? status) {
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

  static String _getStatusPagamento(int? status) {
    switch (status) {
      case 0:
        return 'Pendente';
      case 1:
        return 'Pago';
      default:
        return 'N/A';
    }
  }
}
