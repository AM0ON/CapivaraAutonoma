import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../database/frete_database.dart';
import '../models/frete.dart';
import '../services/cidades.dart';

class NovoFretePage extends StatefulWidget {
  final VoidCallback onSaved;
  final Frete? frete;

  const NovoFretePage({
    super.key,
    required this.onSaved,
    this.frete,
  });

  @override
  State<NovoFretePage> createState() => _NovoFretePageState();
}

class _NovoFretePageState extends State<NovoFretePage> {
  final _formKey = GlobalKey<FormState>();

  final empresa = TextEditingController();
  final contratante = TextEditingController();
  final documento = TextEditingController();
  final telefone = TextEditingController();

  final origem = TextEditingController();
  final destino = TextEditingController();

  final valorFrete = TextEditingController();
  final valorPago = TextEditingController();
  final saldoAberto = TextEditingController();

  final FreteDatabase database = FreteDatabase.instance;

  @override
  void initState() {
    super.initState();
    CidadeService.init();

    telefone.text = '+55 ';

    if (widget.frete != null) {
      final f = widget.frete!;
      empresa.text = f.empresa;
      contratante.text = f.responsavel;
      documento.text = f.documento;
      telefone.text = f.telefone.isNotEmpty ? f.telefone : '+55 ';
      origem.text = f.origem;
      destino.text = f.destino;

      valorFrete.text = f.valorFrete.toStringAsFixed(2).replaceAll('.', ',');
      valorPago.text = f.valorPago.toStringAsFixed(2).replaceAll('.', ',');

      final aberto = (f.valorFrete - f.valorPago) < 0 ? 0 : (f.valorFrete - f.valorPago);
      saldoAberto.text = aberto.toStringAsFixed(2).replaceAll('.', ',');
    }

    valorFrete.addListener(_recalcularSaldo);
    valorPago.addListener(_recalcularSaldo);
    _recalcularSaldo();
  }

  @override
  void dispose() {
    valorFrete.removeListener(_recalcularSaldo);
    valorPago.removeListener(_recalcularSaldo);

    empresa.dispose();
    contratante.dispose();
    documento.dispose();
    telefone.dispose();
    origem.dispose();
    destino.dispose();
    valorFrete.dispose();
    valorPago.dispose();
    saldoAberto.dispose();

    super.dispose();
  }

  double _parseMoney(String value) {
    final cleaned = value.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  void _recalcularSaldo() {
    final total = _parseMoney(valorFrete.text);
    final pago = _parseMoney(valorPago.text);

    var aberto = total - pago;
    if (aberto < 0) aberto = 0;

    final txt = aberto.toStringAsFixed(2).replaceAll('.', ',');
    if (saldoAberto.text != txt) {
      saldoAberto.text = txt;
    }
  }

  String _statusPagamento(double total, double pago, double aberto) {
    if (total <= 0) return 'Pendente';
    if (aberto <= 0) return 'Pago';
    if (pago > 0) return 'Parcial';
    return 'Pendente';
  }

  Future<void> salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final total = _parseMoney(valorFrete.text);
    final pago = _parseMoney(valorPago.text);

    var aberto = total - pago;
    if (aberto < 0) aberto = 0;

    final frete = Frete(
      id: widget.frete?.id,
      empresa: empresa.text.trim(),
      responsavel: contratante.text.trim(),
      documento: documento.text.trim(),
      telefone: telefone.text.trim(),
      origem: origem.text.trim(),
      destino: destino.text.trim(),
      valorFrete: total,
      valorPago: pago,
      valorFaltante: aberto,
      statusPagamento: _statusPagamento(total, pago, aberto),
      statusFrete: widget.frete?.statusFrete ?? 'Pendente',
      dataColeta: widget.frete?.dataColeta,
      dataEntrega: widget.frete?.dataEntrega,
      motivoRejeicao: widget.frete?.motivoRejeicao,
    );

    if (widget.frete == null) {
      await database.inserirFrete(frete);
    } else {
      await database.updateFrete(frete);
    }

    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _textField(
            label: 'Empresa',
            controller: empresa,
            icon: Icons.business,
            validator: (v) => v == null || v.isEmpty ? 'Informe a empresa' : null,
          ),
          _textField(
            label: 'Contratante',
            controller: contratante,
            icon: Icons.person,
            validator: (v) => v == null || v.isEmpty ? 'Informe o contratante' : null,
          ),
          _textField(
            label: 'Documento de identificação (CNPJ ou CPF)',
            controller: documento,
            icon: Icons.badge,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\.\-\/]')),
            ],
            validator: (v) => v == null || v.isEmpty ? 'Informe o documento' : null,
          ),
          _textField(
            label: 'Telefone',
            controller: telefone,
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              BrasilPhonePrefixFormatter(),
            ],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe o telefone';
              if (!v.startsWith('+55')) return 'O telefone deve iniciar com +55';
              final digits = v.replaceAll(RegExp(r'\D'), '');
              if (digits.length < 12) return 'Telefone incompleto';
              return null;
            },
          ),
          _cityField(
            label: 'Origem',
            controller: origem,
            icon: Icons.my_location,
            validator: (v) => v == null || v.isEmpty ? 'Informe a origem' : null,
          ),
          _cityField(
            label: 'Destino',
            controller: destino,
            icon: Icons.location_on,
            validator: (v) => v == null || v.isEmpty ? 'Informe o destino' : null,
          ),
          _textField(
            label: 'Valor do Frete',
            controller: valorFrete,
            icon: Icons.local_shipping,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
            ],
            validator: (v) {
              final total = _parseMoney(v ?? '');
              if (total <= 0) return 'Informe o valor do frete';
              return null;
            },
          ),
          _textField(
            label: 'Valor pago',
            controller: valorPago,
            icon: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
            ],
            validator: (v) {
              final pago = _parseMoney(v ?? '');
              final total = _parseMoney(valorFrete.text);
              if (pago < 0) return 'Valor inválido';
              if (total > 0 && pago > total) return 'Pago não pode ser maior que o frete';
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: salvar,
              child: const Text('Salvar Frete'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
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
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TypeAheadField<String>(
        suggestionsCallback: (pattern) {
          return CidadeService.search(pattern);
        },
        builder: (context, textController, focusNode) {
          if (textController.text != controller.text) {
            textController.text = controller.text;
            textController.selection =
                TextSelection.collapsed(offset: textController.text.length);
          }

          return TextFormField(
            controller: textController,
            focusNode: focusNode,
            validator: (_) => validator?.call(controller.text),
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onChanged: (value) => controller.text = value,
          );
        },
        itemBuilder: (context, suggestion) {
          return ListTile(title: Text(suggestion));
        },
        onSelected: (suggestion) {
          controller.text = suggestion;
          FocusManager.instance.primaryFocus?.unfocus();
        },
      ),
    );
  }
}

class BrasilPhonePrefixFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9\+]'), '');

    if (!text.startsWith('+55')) {
      text = '+55 ${text.replaceFirst(RegExp(r'^55'), '')}';
    }

    if (text == '+55') text = '+55 ';

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
