import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/frete_database.dart';

class RelatorioPage extends StatefulWidget {
  const RelatorioPage({super.key});

  @override
  State<RelatorioPage> createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  final FreteDatabase database = FreteDatabase.instance;
  final NumberFormat _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  bool _carregando = true;
  double _receitaBruta = 0;
  double _custoDespesas = 0;
  double _lucroLiquido = 0;
  int _totalViagens = 0;

  @override
  void initState() {
    super.initState();
    _gerarRelatorio();
  }

  Future<void> _gerarRelatorio() async {
    setState(() => _carregando = true);
    
    final fretes = await database.listarFretes();
    double totalBase = 0;
    double totalDespesasGeral = 0;

    for (var frete in fretes) {
      totalBase += frete.valorBase;
      final despesas = await database.listarDespesasPorFreteId(frete.id);
      totalDespesasGeral += despesas.fold(0.0, (s, d) => s + d.valor);
    }

    if (!mounted) return;

    setState(() {
      _totalViagens = fretes.length;
      _receitaBruta = totalBase;
      _custoDespesas = totalDespesasGeral;
      _lucroLiquido = totalBase - totalDespesasGeral;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório Meu Frete'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _gerarRelatorio,
          )
        ],
      ),
      body: _carregando 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildCardDestaque(),
              const SizedBox(height: 24),
              _buildLinhaResumo('Total de Viagens', '$_totalViagens', Icons.local_shipping_outlined),
              _buildLinhaResumo('Faturamento Bruto', _formatador.format(_receitaBruta), Icons.account_balance_wallet_outlined),
              _buildLinhaResumo('Total em Despesas', _formatador.format(_custoDespesas), Icons.money_off_csred_outlined, corValor: Colors.red),
              const Divider(height: 40),
              _buildSetoresAnalise(),
            ],
          ),
    );
  }

  Widget _buildCardDestaque() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text('LUCRO LÍQUIDO REAL', 
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_formatador.format(_lucroLiquido), 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLinhaResumo(String label, String valor, IconData icone, {Color? corValor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icone, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          const Spacer(),
          Text(valor, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: corValor)),
        ],
      ),
    );
  }

  Widget _buildSetoresAnalise() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Distribuição de Custos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('Análise de categorias em breve', 
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}