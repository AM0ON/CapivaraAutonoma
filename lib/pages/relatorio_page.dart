import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

import '../database/frete_database.dart';
import '../models/frete.dart';

class RelatorioPage extends StatefulWidget {
  const RelatorioPage({super.key});

  @override
  State<RelatorioPage> createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  bool _gerando = false;

  DateTime? inicio;
  DateTime? fim;

  final _dataFormatada = DateFormat('dd/MM/yyyy');

  List<BoxShadow> _sombraPadrao(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: escuro ? Colors.black.withOpacity(0.35) : Colors.black12,
        blurRadius: escuro ? 10 : 6,
        offset: const Offset(0, 6),
      ),
    ];
  }

  Future<void> _selecionarInicio() async {
    final agora = DateTime.now();
    final selecionado = await showDatePicker(
      context: context,
      initialDate: inicio ?? agora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selecionado == null) return;

    setState(() {
      inicio = DateTime(selecionado.year, selecionado.month, selecionado.day);
      if (fim != null && fim!.isBefore(inicio!)) {
        fim = null;
      }
    });
  }

  Future<void> _selecionarFim() async {
    final agora = DateTime.now();
    final base = fim ?? inicio ?? agora;

    final selecionado = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: inicio ?? DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selecionado == null) return;

    setState(() {
      fim = DateTime(selecionado.year, selecionado.month, selecionado.day);
    });
  }

  void _limparPeriodo() {
    setState(() {
      inicio = null;
      fim = null;
    });
  }

  DateTime? _parseIso(String? value) {
    if (value == null) return null;
    final v = value.trim();
    if (v.isEmpty) return null;
    return DateTime.tryParse(v);
  }

  bool _freteDentroDoPeriodo(Frete f) {
    if (inicio == null && fim == null) return true;

    final dEntrega = _parseIso(f.dataEntrega);
    final dColeta = _parseIso(f.dataColeta);

    final dataBase = dEntrega ?? dColeta;
    if (dataBase == null) return false;

    final dataDia = DateTime(dataBase.year, dataBase.month, dataBase.day);

    if (inicio != null && dataDia.isBefore(inicio!)) return false;
    if (fim != null && dataDia.isAfter(fim!)) return false;

    return true;
  }

  Widget _linhaInfo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _gerarPDF() async {
    setState(() => _gerando = true);

    try {
      final fretes = await FreteDatabase.instance.getFretes();
      final filtrados = fretes.where(_freteDentroDoPeriodo).toList();

      final pdf = pw.Document();
      double totalRecebido = 0;

      final periodoTexto = (inicio == null && fim == null)
          ? 'Período: todos os registros'
          : 'Período: '
              '${inicio != null ? _dataFormatada.format(inicio!) : '...'}'
              ' até '
              '${fim != null ? _dataFormatada.format(fim!) : '...'}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Text(
              'Relatório de Fretes',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(periodoTexto, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 6),
            pw.Text('Itens: ${filtrados.length}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: const ['Empresa', 'Rota', 'Valor', 'Pago', 'Aberto', 'Status'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              data: filtrados.map((Frete f) {
                totalRecebido += f.valorPago;
                return [
                  f.empresa,
                  '${f.origem} → ${f.destino}',
                  f.valorFrete.toStringAsFixed(2),
                  f.valorPago.toStringAsFixed(2),
                  f.valorFaltante.toStringAsFixed(2),
                  f.statusFrete,
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total recebido: R\$ ${totalRecebido.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodoSelecionado = inicio != null || fim != null;

    String textoPeriodo() {
      if (!periodoSelecionado) return 'Período: todos os registros';
      final a = inicio != null ? _dataFormatada.format(inicio!) : '...';
      final b = fim != null ? _dataFormatada.format(fim!) : '...';
      return 'Período selecionado: $a até $b';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _sombraPadrao(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Sobre este relatório',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Este relatório reúne um resumo financeiro dos seus fretes, '
                    'organizando valores e status de forma clara para conferência '
                    'e controle.',
                    style: TextStyle(height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  _linhaInfo('Valores totais, pagos e em aberto'),
                  _linhaInfo('Status de cada frete (pendente, coletado, entregue ou rejeitado)'),
                  _linhaInfo('Rotas de origem e destino'),
                  _linhaInfo('Filtro opcional por período de datas'),
                  const SizedBox(height: 16),
                  const Text('Período (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selecionarInicio,
                          icon: const Icon(Icons.event),
                          label: Text(inicio == null ? 'Início' : _dataFormatada.format(inicio!)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selecionarFim,
                          icon: const Icon(Icons.event_available),
                          label: Text(fim == null ? 'Fim' : _dataFormatada.format(fim!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          textoPeriodo(),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.75),
                          ),
                        ),
                      ),
                      if (periodoSelecionado)
                        TextButton(
                          onPressed: _limparPeriodo,
                          child: const Text('Limpar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _gerando ? null : _gerarPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(_gerando ? 'Gerando PDF...' : 'Gerar Relatório PDF'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
