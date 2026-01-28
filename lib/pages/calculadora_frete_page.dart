import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CalculadoraFretePage extends StatefulWidget {
  const CalculadoraFretePage({super.key});

  @override
  State<CalculadoraFretePage> createState() => _CalculadoraFretePageState();
}

class _CalculadoraFretePageState extends State<CalculadoraFretePage> {
  final _distanciaCtrl = TextEditingController();
  final _freteCtrl = TextEditingController();
  final _consumoCtrl = TextEditingController();
  final _combustivelCtrl = TextEditingController();
  final _pedagioCtrl = TextEditingController();

  final NumberFormat _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double _lucro = 0;
  double _custoCombustivel = 0;
  double _custoPedagio = 0;
  double _margemLucro = 0; // Nova variável para a margem
  bool _calculado = false;

  void _calcular() {
    double d = double.tryParse(_distanciaCtrl.text.replaceAll(',', '.')) ?? 0;
    double f = double.tryParse(_freteCtrl.text.replaceAll(',', '.')) ?? 0;
    double c = double.tryParse(_consumoCtrl.text.replaceAll(',', '.')) ?? 1;
    double p = double.tryParse(_combustivelCtrl.text.replaceAll(',', '.')) ?? 0;
    double pedagio = double.tryParse(_pedagioCtrl.text.replaceAll(',', '.')) ?? 0;

    setState(() {
      _custoCombustivel = (d / c) * p;
      _custoPedagio = pedagio;
      _lucro = f - _custoCombustivel - _custoPedagio;
      
      // Cálculo da margem de lucro estimada
      _margemLucro = f > 0 ? (_lucro / f) * 100 : 0;
      
      _calculado = true;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;

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
            // --- CARD DE RESULTADO ---
            _buildResultCard(),

            const SizedBox(height: 20),

            // --- SEÇÃO DE ENTRADA DE DADOS ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(escuro ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Custos e Valores", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(child: _campoInput(_distanciaCtrl, "Distância", "KM", FontAwesomeIcons.route)),
                      const SizedBox(width: 12),
                      Expanded(child: _campoInput(_consumoCtrl, "Média", "KM/L", FontAwesomeIcons.gasPump)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _campoInput(_freteCtrl, "Valor Bruto do Frete", "R\$", FontAwesomeIcons.moneyBillWave),
                  const SizedBox(height: 16),
                  _campoInput(_combustivelCtrl, "Preço do Combustível", "R\$", FontAwesomeIcons.fillDrip),
                  const SizedBox(height: 16),
                  _campoInput(_pedagioCtrl, "Total de Pedágio", "R\$", FontAwesomeIcons.road),
                  
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
                        shadowColor: Colors.blue.withOpacity(0.4),
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

  Widget _buildResultCard() {
    final isPositivo = _lucro >= 0;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositivo 
            ? [const Color(0xFF1B5E20), const Color(0xFF43A047)]
            : [const Color(0xFFB71C1C), const Color(0xFFE53935)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isPositivo ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Text(
            isPositivo ? "LUCRO LÍQUIDO ESTIMADO" : "PREJUÍZO DETECTADO",
            style: TextStyle(color: Colors.white.withOpacity(0.7), letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            _currency.format(_lucro),
            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900),
          ),
          
          // --- MENSAGEM DE AVISO (SOLICITADA) ---
          const SizedBox(height: 4),
          const Text(
            "Calculo sem considerar alimentação e outros custos.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
          ),

          if (_calculado) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStatus("Margem", "${_margemLucro.toStringAsFixed(1)}%"), // Margem solicitada
                _miniStatus("Combustível", _currency.format(_custoCombustivel)),
                _miniStatus("Pedágio", _currency.format(_custoPedagio)),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _miniStatus(String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
      ],
    );
  }

  Widget _campoInput(TextEditingController ctrl, String label, String sufixo, IconData icone) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FaIcon(icone, size: 18, color: Colors.blue.shade700),
        ),
        suffixText: sufixo,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.blue.shade700, width: 2)),
        floatingLabelStyle: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
      ),
    );
  }
}