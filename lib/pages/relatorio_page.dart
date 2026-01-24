import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../database/frete_database.dart';
import '../models/frete.dart';

class RelatorioPage extends StatefulWidget {
  const RelatorioPage({super.key});

  @override
  State<RelatorioPage> createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  bool _gerando = false;

  Future<void> _gerarPDF() async {
    setState(() => _gerando = true);

    try {
      final fretes = await FreteDatabase.instance.getFretes();

      final ids = <int>[];
      for (final f in fretes) {
        if (f.id != null) ids.add(f.id!);
      }

      final totaisDespesas = await FreteDatabase.instance.getTotaisDespesasPorFrete(ids);

      final pdf = pw.Document();

      double totalBrutoGeral = 0;
      double totalDespesasGeral = 0;
      double totalLiquidoGeral = 0;
      double totalPagoGeral = 0;
      double totalAbertoGeral = 0;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            final data = <List<String>>[];

            for (final Frete f in fretes) {
              final id = f.id ?? 0;
              final despesas = totaisDespesas[id] ?? 0.0;

              final liquido = f.valorFrete;
              final bruto = liquido + despesas;

              totalBrutoGeral += bruto;
              totalDespesasGeral += despesas;
              totalLiquidoGeral += liquido;
              totalPagoGeral += f.valorPago;
              totalAbertoGeral += f.valorFaltante;

              final motivo = (f.motivoRejeicao ?? '').trim();

              data.add([
                f.empresa,
                f.responsavel,
                f.telefone,
                '${f.origem} → ${f.destino}',
                bruto.toStringAsFixed(2),
                despesas.toStringAsFixed(2),
                liquido.toStringAsFixed(2),
                f.valorPago.toStringAsFixed(2),
                f.valorFaltante.toStringAsFixed(2),
                f.statusFrete,
                motivo,
              ]);
            }

            return [
              pw.Text(
                'Relatório de Fretes - Gerência Sallex',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Itens: ${fretes.length}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 14),
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Empresa',
                  'Contratante',
                  'Telefone',
                  'Rota',
                  'Total (Bruto) R\$',
                  'Despesas R\$',
                  'Líquido R\$',
                  'Pago R\$',
                  'Aberto R\$',
                  'Status',
                  'Motivo',
                ],
                data: data,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.1),
                  1: pw.FlexColumnWidth(1.0),
                  2: pw.FlexColumnWidth(0.85),
                  3: pw.FlexColumnWidth(1.25),
                  4: pw.FlexColumnWidth(0.9),
                  5: pw.FlexColumnWidth(0.9),
                  6: pw.FlexColumnWidth(0.9),
                  7: pw.FlexColumnWidth(0.8),
                  8: pw.FlexColumnWidth(0.8),
                  9: pw.FlexColumnWidth(0.8),
                  10: pw.FlexColumnWidth(1.4),
                },
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.6),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Totais gerais',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Bruto: R\$ ${totalBrutoGeral.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Total Despesas: R\$ ${totalDespesasGeral.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Líquido: R\$ ${totalLiquidoGeral.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Total Pago: R\$ ${totalPagoGeral.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Total Aberto: R\$ ${totalAbertoGeral.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _gerando ? null : _gerarPDF,
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(_gerando ? 'Gerando PDF...' : 'Gerar Relatório PDF'),
          ),
        ),
      ),
    );
  }
}
