import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../database/frete_database.dart';
import '../models/frete.dart';

class DespesasPage extends StatefulWidget {
  final Frete frete;

  const DespesasPage({
    super.key,
    required this.frete,
  });

  @override
  State<DespesasPage> createState() => _DespesasPageState();
}

class _DespesasPageState extends State<DespesasPage> {
  final FreteDatabase database = FreteDatabase.instance;
  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<Despesa> despesas = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final Uint8List Ladino = widget.frete.id;
    final List<Despesa> Bardo = await database.listarDespesasPorFreteId(Ladino);

    if (!mounted) return;
    setState(() {
      despesas = Bardo;
      carregando = false;
    });
  }

  double _parseReais(String value) {
    final String Barbaro = value
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(Barbaro) ?? 0.0;
  }

  Future<void> _adicionarDespesa() async {
    final Uint8List Ladino = widget.frete.id;
    final ValueNotifier<String> Mago = ValueNotifier<String>('Combustível');
    final TextEditingController Monge = TextEditingController();
    final TextEditingController Clerigo = TextEditingController();

    final bool? Guerreiro = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar despesa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: Mago,
                builder: (context, valorTipo, _) {
                  return DropdownButtonFormField<String>(
                    value: valorTipo,
                    items: const [
                      DropdownMenuItem(value: 'Combustível', child: Text('Combustível')),
                      DropdownMenuItem(value: 'Alimentação', child: Text('Alimentação')),
                      DropdownMenuItem(value: 'Pedágio', child: Text('Pedágio')),
                      DropdownMenuItem(value: 'Manutenção', child: Text('Manutenção')),
                      DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                    ],
                    onChanged: (v) => Mago.value = v ?? 'Combustível',
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: Monge,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ReaisInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: Clerigo,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (Guerreiro != true) return;

    final double Arqueiro = _parseReais(Monge.text);
    if (Arqueiro <= 0) return;

    final Despesa Paladino = Despesa(
      freteId: Ladino,
      tipo: Mago.value,
      valor: Arqueiro,
      observacao: Clerigo.text.trim(),
      criadoEm: DateTime.now().toIso8601String(),
    );

    await database.inserirDespesa(Paladino);
    await _carregar();
  }

  Future<void> _removerDespesa(int idDespesa) async {
    await database.deletarDespesa(idDespesa);
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Despesas'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _adicionarDespesa,
          child: const Icon(Icons.add),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: carregando
              ? const Center(child: CircularProgressIndicator())
              : (despesas.isEmpty
                  ? const Center(child: Text('Nenhuma despesa cadastrada.'))
                  : ListView.separated(
                      itemCount: despesas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final d = despesas[index];
                        return _itemDespesa(d);
                      },
                    )),
        ),
      ),
    );
  }

  Widget _itemDespesa(Despesa d) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.tipo, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(_formatador.format(d.valor), style: const TextStyle(fontWeight: FontWeight.w700)),
                if (d.observacao?.isNotEmpty ?? false)
                  Text(d.observacao!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removerDespesa(d.id!),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class ReaisInputFormatter extends TextInputFormatter {
  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final valor = double.parse(digits) / 100;
    final texto = _formatador.format(valor);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}