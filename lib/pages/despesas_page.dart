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
    final id = widget.frete.id;
    if (id == null) {
      setState(() {
        despesas = [];
        carregando = false;
      });
      return;
    }

    final lista = await database.getDespesas(id);

    setState(() {
      despesas = lista;
      carregando = false;
    });
  }

  double _parseReais(String value) {
    final txt = value
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(txt) ?? 0.0;
  }

  String _statusPagamento(double total, double pago, double aberto) {
    if (total <= 0) return 'Pendente';
    if (aberto <= 0) return 'Pago';
    if (pago > 0) return 'Parcial';
    return 'Pendente';
  }

  Future<void> _recalcularEAtualizarFrete() async {
    final id = widget.frete.id;
    if (id == null) return;

    // CORREÇÃO AQUI: As despesas não entram mais no cálculo do 'aberto'
    // O 'aberto' é apenas o que a empresa deve (Total - Pago)
    
    final total = widget.frete.valorFrete;
    final pago = widget.frete.valorPago;

    var aberto = total - pago; // Removido: "- totalDespesas"
    if (aberto < 0) aberto = 0;

    final atualizado = widget.frete.copyWith(
      valorFaltante: aberto,
      statusPagamento: _statusPagamento(total, pago, aberto),
    );

    await database.updateFrete(atualizado);
  }

  Future<void> _adicionarDespesa() async {
    final id = widget.frete.id;
    if (id == null) return;

    final tipo = ValueNotifier<String>('Combustivel');
    final valor = TextEditingController();
    final observacao = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar despesa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: tipo,
                builder: (context, valorTipo, _) {
                  return DropdownButtonFormField<String>(
                    value: valorTipo,
                    items: const [
                      DropdownMenuItem(value: 'Combustivel', child: Text('Combustivel')),
                      DropdownMenuItem(value: 'Alimentação', child: Text('Alimentação')),
                      DropdownMenuItem(value: 'Manutenção', child: Text('Manutenção')),
                      DropdownMenuItem(value: 'Avulsos', child: Text('Avulsos')),
                      DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                    ],
                    onChanged: (v) => tipo.value = v ?? 'Combustivel',
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valor,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ReaisInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: observacao,
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

    if (confirmado != true) return;

    final valorDespesa = _parseReais(valor.text);
    if (valorDespesa <= 0) return;

    final novaDespesa = Despesa(
      freteId: id,
      tipo: tipo.value,
      valor: valorDespesa,
      observacao: observacao.text.trim(),
      criadoEm: DateTime.now().toIso8601String(),
    );

    await database.inserirDespesa(novaDespesa);

    await _recalcularEAtualizarFrete();
    await _carregar();
    
    if (!mounted) return;
  }

  Future<void> _removerDespesa(int idDespesa) async {
    await database.deleteDespesa(idDespesa);
    await _recalcularEAtualizarFrete();
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.frete.id;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Despesas'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: id == null ? null : _adicionarDespesa,
          child: const Icon(Icons.add),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: carregando
              ? const Center(child: CircularProgressIndicator())
              : (despesas.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma despesa cadastrada.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      itemCount: despesas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final d = despesas[index];

                        final idDespesa = d.id ?? 0;
                        final tipo = d.tipo;
                        final obs = (d.observacao ?? '').trim();
                        final valor = d.valor;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withOpacity(0.1),
                                ),
                                child: const Icon(Icons.receipt_long, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tipo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatador.format(valor),
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    if (obs.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        obs,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removerDespesa(idDespesa),
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    )),
        ),
      ),
    );
  }
}

class ReaisInputFormatter extends TextInputFormatter {
  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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