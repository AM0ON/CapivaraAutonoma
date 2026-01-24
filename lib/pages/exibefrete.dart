import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';

import '../database/frete_database.dart';
import '../models/frete.dart';
import '../services/cidades.dart';

class ExibeFretePage extends StatefulWidget {
  final Frete frete;

  const ExibeFretePage({
    super.key,
    required this.frete,
  });

  @override
  State<ExibeFretePage> createState() => _ExibeFretePageState();
}

class _ExibeFretePageState extends State<ExibeFretePage> {
  final _formKey = GlobalKey<FormState>();
  final FreteDatabase database = FreteDatabase.instance;

  final empresa = TextEditingController();
  final responsavel = TextEditingController();
  final documento = TextEditingController();
  final telefone = TextEditingController();

  final origem = TextEditingController();
  final destino = TextEditingController();

  final focoOrigem = FocusNode();
  final focoDestino = FocusNode();

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

    focoOrigem.dispose();
    focoDestino.dispose();

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
            _textField(
              label: 'Empresa',
              controller: empresa,
              icon: Icons.business,
              validator: (v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            _textField(
              label: 'Contratante',
              controller: responsavel,
              icon: Icons.person,
              validator: (v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            _textField(
              label: 'Documento de identificação (CNPJ ou CPF)',
              controller: documento,
              icon: Icons.badge,
              validator: (v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            _textField(
              label: 'Telefone',
              controller: telefone,
              icon: Icons.phone,
              validator: (v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            _cityField(
              label: 'Origem',
              controller: origem,
              focusNode: focoOrigem,
              icon: Icons.my_location,
              validator: (v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            _cityField(
              label: 'Destino',
              controller: destino,
              focusNode: focoDestino,
              icon: Icons.location_on,
              validator: (v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
            ),
            _moneyField(
              label: 'Valor do Frete (bruto)',
              controller: valorFreteBruto,
              icon: Icons.local_shipping,
            ),
            _moneyField(
              label: 'Valor pago',
              controller: valorPago,
              icon: Icons.attach_money,
            ),
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
                labelText: 'Saldo em aberto',
                prefixIcon: const Icon(Icons.account_balance),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
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

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _moneyField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [ReaisInputFormatter()],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _cityField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TypeAheadField<String>(
        controller: controller,
        focusNode: focusNode,
        debounceDuration: const Duration(milliseconds: 200),
        suggestionsCallback: (pattern) {
          return CidadeService.search(pattern);
        },
        emptyBuilder: (context) => const SizedBox.shrink(),
        builder: (context, textController, focusNode) {
          return TextFormField(
            controller: textController,
            focusNode: focusNode,
            validator: (_) => validator?.call(textController.text),
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        },
        itemBuilder: (context, suggestion) {
          return ListTile(title: Text(suggestion));
        },
        onSelected: (suggestion) {
          controller.text = suggestion;
          controller.selection = TextSelection.collapsed(offset: controller.text.length);
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
