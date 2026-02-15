import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

import '../database/frete_database.dart';
import '../models/frete.dart';
import '../services/cidades.dart';

class NovoFretePage extends StatefulWidget {
  final VoidCallback aoSalvar;
  final Frete? frete;

  const NovoFretePage({
    super.key,
    required this.aoSalvar,
    this.frete,
  });

  @override
  State<NovoFretePage> createState() => _NovoFretePageState();
}

class _NovoFretePageState extends State<NovoFretePage> {
  final _formKey = GlobalKey<FormState>();

  final empresa = TextEditingController();
  final responsavel = TextEditingController();
  final documento = TextEditingController();
  final telefone = TextEditingController();
  final origem = TextEditingController();
  final destino = TextEditingController();
  final valorBase = TextEditingController();

  final focoOrigem = FocusNode();
  final focoDestino = FocusNode();

  final FreteDatabase database = FreteDatabase.instance;

  @override
  void initState() {
    super.initState();
    CidadeService.init();
    
    if (widget.frete != null) {
      final f = widget.frete!;
      empresa.text = f.empresa;
      responsavel.text = f.responsavel;
      documento.text = f.documento;
      telefone.text = f.telefone;
      origem.text = f.origem;
      destino.text = f.destino;
      valorBase.text = f.valorBase.toStringAsFixed(2).replaceAll('.', ',');
    } else {
      telefone.text = '+55 ';
    }
  }

  @override
  void dispose() {
    focoOrigem.dispose();
    focoDestino.dispose();
    empresa.dispose();
    responsavel.dispose();
    documento.dispose();
    telefone.dispose();
    origem.dispose();
    destino.dispose();
    valorBase.dispose();
    super.dispose();
  }

  double _sanitizarMoeda(String valor) {
    final limpo = valor.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo) ?? 0.0;
  }

  Future<void> salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final base = _sanitizarMoeda(valorBase.text);
    final Uint8List idSeguro = widget.frete?.id ?? Uint8List.fromList(const Uuid().v7obj().toBytes());

    final novoFrete = Frete(
      id: idSeguro,
      empresa: empresa.text.trim(),
      responsavel: responsavel.text.trim(),
      documento: documento.text.trim(),
      telefone: telefone.text.trim(),
      origem: origem.text.trim(),
      destino: destino.text.trim(),
      valorBase: base,
      taxaMediacao: base * 0.05,
      taxasPsp: widget.frete?.taxasPsp ?? 0.0,
      
      // CORREÇÃO AQUI: Se for um frete novo, entra como 'aguardandoPagamento'
      status: widget.frete?.status ?? StatusFrete.aguardandoPagamento,
      
      chavePixMotorista: widget.frete?.chavePixMotorista,
      dataColeta: widget.frete?.dataColeta,
      dataEntrega: widget.frete?.dataEntrega,
    );

    if (widget.frete == null) {
      await database.inserirFrete(novoFrete);
    } else {
      await database.atualizarFrete(novoFrete);
    }

    widget.aoSalvar();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _campoTexto(
            rotulo: 'Empresa Embarcadora',
            controller: empresa,
            icone: Icons.business,
            validador: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
          ),
          _campoTexto(
            rotulo: 'Nome do Responsável',
            controller: responsavel,
            icone: Icons.person_outline,
            validador: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
          ),
          _campoTexto(
            rotulo: 'CPF ou CNPJ',
            controller: documento,
            icone: Icons.description_outlined,
            teclado: TextInputType.number,
            formatadores: [FilteringTextInputFormatter.digitsOnly],
            validador: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
          ),
          _campoTexto(
            rotulo: 'WhatsApp / Telefone',
            controller: telefone,
            icone: Icons.phone_android,
            teclado: TextInputType.phone,
            validador: (v) => v == null || v.length < 10 ? 'Telefone inválido' : null,
          ),
          _campoCidade(
            rotulo: 'Cidade de Origem',
            controller: origem,
            icone: Icons.location_on_outlined,
          ),
          _campoCidade(
            rotulo: 'Cidade de Destino',
            controller: destino,
            icone: Icons.flag_outlined,
          ),
          _campoTexto(
            rotulo: 'Valor Acertado com Motorista (R\$)',
            controller: valorBase,
            icone: Icons.monetization_on_outlined,
            teclado: const TextInputType.numberWithOptions(decimal: true),
            validador: (v) => _sanitizarMoeda(v ?? '') <= 0 ? 'Valor inválido' : null,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: salvar,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('SALVAR NO MEU FRETE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoTexto({
    required String rotulo,
    required TextEditingController controller,
    required IconData icone,
    TextInputType? teclado,
    List<TextInputFormatter>? formatadores,
    String? Function(String?)? validador,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: teclado,
        inputFormatters: formatadores,
        validator: validador,
        decoration: InputDecoration(
          labelText: rotulo,
          prefixIcon: Icon(icone),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _campoCidade({
    required String rotulo,
    required TextEditingController controller,
    required IconData icone,
  }) {
    final node = controller == origem ? focoOrigem : focoDestino;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TypeAheadField<String>(
        controller: controller,
        focusNode: node,
        builder: (context, controller, focusNode) => TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: rotulo,
            prefixIcon: Icon(icone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        suggestionsCallback: (busca) => CidadeService.search(busca),
        itemBuilder: (context, sugestao) => ListTile(title: Text(sugestao)),
        onSelected: (sugestao) => controller.text = sugestao,
      ),
    );
  }
}