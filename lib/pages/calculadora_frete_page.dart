import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CalculadoraFretePage extends StatefulWidget {
  const CalculadoraFretePage({super.key});

  @override
  State<CalculadoraFretePage> createState() => _CalculadoraFretePageState();
}

class _CalculadoraFretePageState extends State<CalculadoraFretePage> {
  // Controladores
  final _distanciaCtrl = TextEditingController();
  final _freteCtrl = TextEditingController();
  final _consumoCtrl = TextEditingController();
  final _combustivelCtrl = TextEditingController();
  final _pedagioCtrl = TextEditingController();
  final _margemDesejadaCtrl = TextEditingController(text: "20");

  final NumberFormat _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Variáveis de Cálculo
  double _lucro = 0;
  double _custoCombustivel = 0;
  double _custoPedagio = 0;
  double _litrosNecessarios = 0;
  double _freteBruto = 0;
  double _margemCalculada = 0;
  bool _calculado = false;

  void _calcular() {
    double d = double.tryParse(_distanciaCtrl.text.replaceAll(',', '.')) ?? 0;
    double f = double.tryParse(_freteCtrl.text.replaceAll(',', '.')) ?? 0;
    double c = double.tryParse(_consumoCtrl.text.replaceAll(',', '.')) ?? 1;
    double p = double.tryParse(_combustivelCtrl.text.replaceAll(',', '.')) ?? 0;
    double pedagio = double.tryParse(_pedagioCtrl.text.replaceAll(',', '.')) ?? 0;

    setState(() {
      _freteBruto = f;
      _litrosNecessarios = d / c;
      _custoCombustivel = _litrosNecessarios * p;
      _custoPedagio = pedagio;
      _lucro = f - _custoCombustivel - _custoPedagio;
      _margemCalculada = f > 0 ? (_lucro / f) * 100 : 0;
      _calculado = true;
    });
    FocusScope.of(context).unfocus();
  }

  Map<String, dynamic> _obterStatusMargem() {
    double desejada = double.tryParse(_margemDesejadaCtrl.text.replaceAll(',', '.')) ?? 0;
    if (_margemCalculada > desejada) {
      return {'cor': Colors.green.shade700, 'texto': '(Acima da Margem Desejada)', 'icone': '🚀'};
    } else if (_margemCalculada == desejada) {
      return {'cor': Colors.orange.shade700, 'texto': '(Dentro da Margem)', 'icone': '✅'};
    } else {
      return {'cor': Colors.red.shade700, 'texto': '(Valor Abaixo da Margem)', 'icone': '⚠️'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final status = _calculado ? _obterStatusMargem() : null;

    return Scaffold(
      backgroundColor: escuro ? const Color(0xFF0E1116) : const Color(0xFFF6F6FA),
      appBar: AppBar(
        title: const Text("Dashboard de Viagem", style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            if (_calculado) ...[
              _buildResultCard(status!),
              const SizedBox(height: 16),
              _buildDetalhamento(escuro), // Nova seção solicitada
            ],

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(escuro ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Custos e Metas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _campoInput(_margemDesejadaCtrl, "Sua Meta de Margem 🎯", "%", destaca: true),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(child: _campoInput(_distanciaCtrl, "Distância 🛣️", "KM")),
                      const SizedBox(width: 12),
                      Expanded(child: _campoInput(_consumoCtrl, "Média ⛽", "KM/L")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _campoInput(_freteCtrl, "Valor Bruto do Frete 💰", "R\$"),
                  const SizedBox(height: 16),
                  _campoInput(_combustivelCtrl, "Preço do Combustível 🛢️", "R\$"),
                  const SizedBox(height: 16),
                  _campoInput(_pedagioCtrl, "Total de Pedágio 🛣️", "R\$"),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _calcular,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: const Text("CALCULAR RENTABILIDADE", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: status['cor'],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: status['cor'].withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text("LUCRO LÍQUIDO ESTIMADO", style: TextStyle(color: Colors.white.withOpacity(0.7), letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          Text(_currency.format(_lucro), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(status['icone'], style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(status['texto'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Calculo sem considerar alimentação e outros custos.", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- SEÇÃO DE DETALHAMENTO (O QUE FOI CONSIDERADO) ---
  Widget _buildDetalhamento(bool escuro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: escuro ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("O que foi considerado: 📝", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _itemDetalhamento("Faturamento Bruto:", _currency.format(_freteBruto), Colors.blue),
          _itemDetalhamento("Combustível Consumido:", "${_litrosNecessarios.toStringAsFixed(1)} Litros", null),
          _itemDetalhamento("Custo do Combustível:", "- ${_currency.format(_custoCombustivel)}", Colors.red),
          _itemDetalhamento("Custo de Pedágios:", "- ${_currency.format(_custoPedagio)}", Colors.red),
          const Divider(),
          _itemDetalhamento("Margem de Lucro Real:", "${_margemCalculada.toStringAsFixed(1)}%", Colors.orange.shade800),
        ],
      ),
    );
  }

  Widget _itemDetalhamento(String label, String valor, Color? corValor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: corValor)),
        ],
      ),
    );
  }

  Widget _campoInput(TextEditingController ctrl, String label, String sufixo, {bool destaca = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        suffixText: sufixo,
        filled: true,
        fillColor: destaca ? Colors.blue.withOpacity(0.1) : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.blue.shade700, width: 2)),
        floatingLabelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
    );
  }
}