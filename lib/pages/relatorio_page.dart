import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../database/frete_database.dart';

class RelatorioPage extends StatelessWidget {
  const RelatorioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        child: const Text('Gerar PDF'),
        onPressed: () async {
          final db = FreteDatabase.instance;
          final fretes = await db.getFretes();
          final pdf = pw.Document();

          pdf.addPage(
            pw.Page(
              build: (_) => pw.Column(
                children: fretes
                    .map((f) => pw.Text('${f.empresa} - R\$ ${f.valorFrete.toStringAsFixed(2)}'))
                    .toList(),
              ),
            ),
          );

          await Printing.layoutPdf(onLayout: (_) => pdf.save());
        },
      ),
    );
  }
}
