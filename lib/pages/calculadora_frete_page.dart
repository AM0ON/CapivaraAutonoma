import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CalculadoraFretePage extends StatefulWidget {
  const CalculadoraFretePage({super.key});

  @override
  State<CalculadoraFretePage> createState() => _CalculadoraFretePageState();
}

class _CalculadoraFretePageState extends State<CalculadoraFretePage> {
  final _distanciaController = TextEditingController();
  final _valorBaseController = TextEditingController();
  final _consumoMediaController = TextEditingController();
  final _precoCombustivelController = TextEditingController();
  final _pedagioTotalController = TextEditingController();
  final _margemDesejadaController = TextEditingController(text: "20");

  final NumberFormat _formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double _lucroEstimado = 0;
  double _custoCombustivelTotal = 0;
  double _pedagioCalculado = 0;
  double _consumoLitrosNecessarios = 0;
  double _faturamentoBruto = 0;
  double _margemRealCalculada = 0;
  bool _foiCalculado = false;

  void _executarCalculoRentabilidade() {
    final double distancia = _limparEConverter(_distanciaController.text);
    final double valorBaseFrete = _limparEConverter(_valorBaseController.text);
    final double mediaConsumo = _limparEConverter(_consumoMediaController.text, valorPadrao: 1.0);
    final double precoDiesel = _limparEConverter(_precoCombustivelController.text);
    final double pedagios = _limparEConverter(_pedagioTotalController.text);

    setState(() {
      _faturamentoBruto = valorBaseFrete;
      _consumoLitrosNecessarios = distancia / mediaConsumo;
      _custoCombustivelTotal = _consumoLitrosNecessarios * precoDiesel;
      _pedagioCalculado = pedagios;
      
      // O Lucro do Motorista no Meu Frete é o Valor Base menos os custos de estrada.
      // A taxa de 5% da AzorTech é paga pelo embarcador "por fora" do valor base.
      _lucroEstimado = valorBaseFrete - _custoCombustivelTotal - _pedagioCalculado;
      _margemRealCalculada = valorBaseFrete > 0 ? (_lucroEstimado / valorBaseFrete) * 100 : 0;
      _foiCalculado = true;
    });
    
    FocusScope.of(context).unfocus();
  }

  double _limparEConverter(String valor, {double valorPadrao = 0.0}) {
    final String limpo = valor.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo) ?? valorPadrao;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculadora Meu Frete", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            if (_foiCalculado) ...[
              _buildCardResultado(),
              const SizedBox(height: 16),
              _buildDetalhamentoCustos(),
            ],
            const SizedBox(height: 20),
            _buildFormularioEntrada(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCardResultado() {
    final double margemDesejada = _limparEConverter(_margemDesejadaController.text);
    Color corStatus = Colors.red.shade700;
    String textoStatus = "Abaixo da Meta";
    IconData iconeStatus = Icons.warning_amber_rounded;

    if (_margemRealCalculada >= margemDesejada) {
      corStatus = Colors.green.shade700;
      textoStatus = "Excelente Rentabilidade";
      iconeStatus = Icons.rocket_launch;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: corStatus,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text("LUCRO LÍQUIDO ESTIMADO", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Text(_formatadorMoeda.format(_lucroEstimado), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconeStatus, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(textoStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetalhamentoCustos() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _linhaDetalhamento("Faturamento (Base):", _formatadorMoeda.format(_faturamentoBruto)),
          _linhaDetalhamento("Diesel Necessário:", "${_consumoLitrosNecessarios.toStringAsFixed(1)} L"),
          _linhaDetalhamento("Gasto com Diesel:", "- ${_formatadorMoeda.format(_custoCombustivelTotal)}", cor: Colors.red),
          _linhaDetalhamento("Gasto com Pedágio:", "- ${_formatadorMoeda.format(_pedagioCalculado)}", cor: Colors.red),
          const Divider(),
          _linhaDetalhamento("Margem de Lucro:", "${_margemRealCalculada.toStringAsFixed(1)}%", destaque: true),
        ],
      ),
    );
  }

  Widget _linhaDetalhamento(String label, String valor, {Color? cor, bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(valor, style: TextStyle(fontWeight: destaque ? FontWeight.bold : FontWeight.w600, color: cor)),
        ],
      ),
    );
  }

  Widget _buildFormularioEntrada() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          _campoTexto(label: "Sua Meta de Margem (%)", controller: _margemDesejadaController, icone: Icons.track_changes),
          const Divider(height: 32),
          _campoTexto(label: "Distância Total (KM)", controller: _distanciaController, icone: Icons.map),
          _campoTexto(label: "Média de Consumo (KM/L)", controller: _consumoMediaController, icone: Icons.ev_station),
          _campoTexto(label: "Valor Base do Frete (R\$)", controller: _valorBaseController, icone: Icons.monetization_on),
          _campoTexto(label: "Preço do Diesel (R\$)", controller: _precoCombustivelController, icone: Icons.local_gas_station),
          _campoTexto(label: "Pedágio Total (R\$)", controller: _pedagioTotalController, icone: Icons.toll),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _executarCalculoRentabilidade,
              child: const Text("CALCULAR MEU FRETE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoTexto({required String label, required TextEditingController controller, required IconData icone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icone, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}