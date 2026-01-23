import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';

import '../database/frete_database.dart';
import '../models/frete.dart';
import '../services/cidades.dart';

class EditarFretePage extends StatefulWidget {
  final Frete frete;

  const EditarFretePage({
    super.key,
    required this.frete,
  });

  @override
  State<EditarFretePage> createState() => _EditarFretePageState();
}

class _EditarFretePageState extends State<EditarFretePage> {
  final _formKey = GlobalKey<FormState>();
  final FreteDatabase database = FreteDatabase.instance;

  final empresa = TextEditingController();
  final responsavel = TextEditingController();
  final documento = TextEditingController();
  final telefone = TextEditingController();

  final origem = TextEditingController();
  final destino = TextEditingController();

  final valorFreteBruto = TextEditingController();
  final valorPago = TextEditingController();

  final totalDespesasCtrl = TextEditingController();
  final valorLiquidoCtrl = TextEditingController();
  final saldoCtrl = TextEditingController();

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<Map<String, dynamic>> despesas = [];

  @override
  void initState() {
    super.initState();
    CidadeService.init();

    final f = widget.frete;

    empresa.text = f.empresa;
    responsavel.text = f.responsavel;
    documento.text = f.documento;
    telefone.text = f.telefone.isNotEmpty ? f.telefone : '+55 ';
    origem.text = f.origem;
    destino.text = f.destino;

    valorPago.text = _formatador.format(f.valorPago);

    valorFreteBruto.text = _formatador.format(f.valorFrete);
    totalDespesasCtrl.text = _formatador.format(0);
    valorLiquidoCtrl.text = _formatador.format(f.valorFrete);
    saldoCtrl.text = _formatador.format(f.valorFaltante);

    valorFreteBruto.addListener(_recalcularLocal);
    valorPago.addListener(_recalcularLocal);

    _carregarDespesas();
  }

  @override
  void dispose() {
    valorFreteBruto.removeListener(_recalcularLocal);
    valorPago.removeListener(_recalcularLocal);

    empresa.dispose();
    responsavel.dispose();
    documento.dispose();
    telefone.dispose();
    origem.dispose();
    destino.dispose();
    valorFreteBruto.dispose();
    valorPago.dispose();
    totalDespesasCtrl.dispose();
    valorLiquidoCtrl.dispose();
    saldoCtrl.dispose();

    super.dispose();
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

  double _somarDespesasLista() {
    double soma = 0.0;
    for (final d in despesas) {
      final v = d['valor'];
      if (v is num) {
        soma += v.toDouble();
      } else {
        soma += double.tryParse('$v') ?? 0.0;
      }
    }
    return soma;
  }

  String _statusPagamento(double totalLiquido, double pago) {
    if (totalLiquido <= 0) return 'Pendente';
    if (pago <= 0) return 'Pendente';
    if (pago >= totalLiquido) return 'Pago';
    return 'Parcial';
  }

  void _recalcularLocal() {
    final bruto = _parseReais(valorFreteBruto.text);
    final pago = _parseReais(valorPago.text);
    final totalDespesas = _somarDespesasLista();

    var liquido = bruto - totalDespesas;
    if (liquido < 0) liquido = 0;

    var aberto = liquido - pago;
    if (aberto < 0) aberto = 0;

    totalDespesasCtrl.text = _formatador.format(totalDespesas);
    valorLiquidoCtrl.text = _formatador.format(liquido);
    saldoCtrl.text = _formatador.format(aberto);
  }

  Future<void> _carregarDespesas() async {
    final id = widget.frete.id;
    if (id == null) return;

    final lista = await database.listarDespesasDoFrete(id);
    setState(() {
      despesas = lista;
    });

    final brutoAjustado = widget.frete.valorFrete + _somarDespesasLista();
    valorFreteBruto.text = _formatador.format(brutoAjustado);

    _recalcularLocal();
    await _salvarFreteRecalculado();
  }

  Future<void> _salvarFreteRecalculado() async {
    final id = widget.frete.id;
    if (id == null) return;

    final bruto = _parseReais(valorFreteBruto.text);
    final pago = _parseReais(valorPago.text);
    final totalDespesas = await database.totalDespesasDoFrete(id);

    var liquido = bruto - totalDespesas;
    if (liquido < 0) liquido = 0;

    var aberto = liquido - pago;
    if (aberto < 0) aberto = 0;

    final atualizado = Frete(
      id: id,
      empresa: empresa.text.trim(),
      responsavel: responsavel.text.trim(),
      documento: documento.text.trim(),
      telefone: telefone.text.trim(),
      origem: origem.text.trim(),
      destino: destino.text.trim(),
      valorFrete: liquido,
      valorPago: pago,
      valorFaltante: aberto,
      statusPagamento: _statusPagamento(liquido, pago),
      statusFrete: widget.frete.statusFrete,
      dataColeta: widget.frete.dataColeta,
      dataEntrega: widget.frete.dataEntrega,
      motivoRejeicao: widget.frete.motivoRejeicao,
    );

    await database.updateFrete(atualizado);

    totalDespesasCtrl.text = _formatador.format(totalDespesas);
    valorLiquidoCtrl.text = _formatador.format(liquido);
    saldoCtrl.text = _formatador.format(aberto);
  }

  Future<void> _adicionarDespesa() async {
    String tipoSelecionado = 'Combustível';
    final tipoOutro = TextEditingController();
    final valor = TextEditingController();
    final observacao = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final mostrarOutro = tipoSelecionado == 'Outros';
            return AlertDialog(
              title: const Text('Adicionar despesa'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: tipoSelecionado,
                      items: const [
                        DropdownMenuItem(value: 'Combustível', child: Text('Combustível')),
                        DropdownMenuItem(value: 'Alimentação', child: Text('Alimentação')),
                        DropdownMenuItem(value: 'Manutenção', child: Text('Manutenção')),
                        DropdownMenuItem(value: 'Avulsos', child: Text('Avulsos')),
                        DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                      ],
                      onChanged: (v) {
                        setStateDialog(() {
                          tipoSelecionado = v ?? 'Combustível';
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Tipo'),
                    ),
                    if (mostrarOutro) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: tipoOutro,
                        decoration: const InputDecoration(labelText: 'Descreva o tipo'),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: valor,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ReaisInputFormatter()],
                      decoration: const InputDecoration(labelText: 'Valor'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: observacao,
                      decoration: const InputDecoration(labelText: 'Observação (opcional)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmado != true) return;

    final idFrete = widget.frete.id;
    if (idFrete == null) return;

    var tipoFinal = tipoSelecionado;
    if (tipoSelecionado == 'Outros') {
      final t = tipoOutro.text.trim();
      if (t.isNotEmpty) tipoFinal = t;
    }

    final valorNum = _parseReais(valor.text);
    if (tipoFinal.trim().isEmpty || valorNum <= 0) return;

    await database.inserirDespesa(
      freteId: idFrete,
      tipo: tipoFinal.trim(),
      valor: valorNum,
      observacao: observacao.text.trim(),
      criadoEm: DateTime.now().toIso8601String(),
    );

    await _carregarDespesas();
  }

  Future<void> _removerDespesa(Map<String, dynamic> d) async {
    final id = d['id'];
    final idNum = id is int ? id : int.tryParse('$id');
    if (idNum == null) return;

    await database.removerDespesa(idNum);
    await _carregarDespesas();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    await _salvarFreteRecalculado();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final motivo = (widget.frete.motivoRejeicao ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Frete'),
        actions: [
          IconButton(
            onPressed: _salvar,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (motivo.isNotEmpty) ...[
              TextFormField(
                initialValue: motivo,
                readOnly: true,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Motivo da rejeição',
                  prefixIcon: const Icon(Icons.report),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _titulo('Dados do frete'),
            _campoTexto('Empresa', empresa, Icons.business),
            _campoTexto('Contratante', responsavel, Icons.person),
            _campoTexto('Documento de identificação (CNPJ ou CPF)', documento, Icons.badge),
            _campoTexto('Telefone', telefone, Icons.phone),
            _campoCidade('Origem', origem, Icons.my_location),
            _campoCidade('Destino', destino, Icons.location_on),
            const SizedBox(height: 12),
            _titulo('Valores'),
            _campoValor('Valor do Frete (bruto)', valorFreteBruto, Icons.local_shipping),
            _campoValor('Valor pago', valorPago, Icons.attach_money),
            TextFormField(
              controller: totalDespesasCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Total de despesas',
                prefixIcon: const Icon(Icons.receipt_long),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: valorLiquidoCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Valor líquido (Frete - Despesas)',
                prefixIcon: const Icon(Icons.calculate),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: saldoCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Saldo em aberto (já descontando despesas)',
                prefixIcon: const Icon(Icons.account_balance),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 18),
            _titulo('Despesas do frete'),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _adicionarDespesa,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar despesa'),
              ),
            ),
            const SizedBox(height: 12),
            if (despesas.isEmpty)
              const Text('Nenhuma despesa adicionada.', style: TextStyle(color: Colors.grey))
            else
              ...despesas.map((d) {
                final tipo = (d['tipo'] ?? '').toString();
                final obs = (d['observacao'] ?? '').toString();
                final v = d['valor'];
                final valorNum = v is num ? v.toDouble() : (double.tryParse('$v') ?? 0.0);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tipo, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_formatador.format(valorNum)),
                            if (obs.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(obs, style: const TextStyle(color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removerDespesa(d),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              }).toList(),
            const SizedBox(height: 18),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvar,
                child: const Text('Salvar alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titulo(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _campoTexto(String label, TextEditingController c, IconData i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(i),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
      ),
    );
  }

  Widget _campoValor(String label, TextEditingController c, IconData i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [ReaisInputFormatter()],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(i),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        validator: (v) => _parseReais(v ?? '') < 0 ? 'Valor inválido' : null,
      ),
    );
  }

  Widget _campoCidade(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TypeAheadField<String>(
        suggestionsCallback: (pattern) {
          return CidadeService.search(pattern);
        },
        builder: (context, textController, focusNode) {
          if (textController.text != controller.text) {
            textController.text = controller.text;
            textController.selection = TextSelection.collapsed(
              offset: textController.text.length,
            );
          }

          return TextFormField(
            controller: textController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onChanged: (value) => controller.text = value,
            validator: (v) => controller.text.trim().isEmpty ? 'Campo obrigatório' : null,
          );
        },
        itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
        onSelected: (suggestion) {
          controller.text = suggestion;
          FocusManager.instance.primaryFocus?.unfocus();
        },
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
