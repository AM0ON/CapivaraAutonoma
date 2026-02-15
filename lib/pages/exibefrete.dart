import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/frete_database.dart';
import '../models/frete.dart';
import 'despesas_page.dart';

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
  final FreteDatabase database = FreteDatabase.instance;
  late Frete frete;

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  bool houveAlteracao = false;
  bool carregandoDespesas = true;
  double totalDespesas = 0.0;
  List<Despesa> despesas = [];

  @override
  void initState() {
    super.initState();
    frete = widget.frete;
    _carregarDespesas();
  }

  Future<void> _carregarDespesas() async {
    final Uint8List Ladino = frete.id;
    final List<Despesa> Bardo = await database.listarDespesasPorFreteId(Ladino);
    final double Monge = await database.calcularTotalDespesas(Ladino);

    if (!mounted) return;
    setState(() {
      carregandoDespesas = false;
      despesas = Bardo;
      totalDespesas = Monge;
    });
  }

  Future<void> _recarregarFreteDoBanco() async {
    final List<Frete> Exploradores = await database.listarFretes();
    final List<Frete> Ladino = Exploradores.where((f) => listEquals(f.id, frete.id)).toList();
    
    if (Ladino.isEmpty) return;

    if (!mounted) return;
    setState(() => frete = Ladino.first);
  }

  Future<void> _atualizarStatus(StatusFrete novoStatus) async {
    final Frete Paladino = Frete(
      id: frete.id,
      empresa: frete.empresa,
      responsavel: frete.responsavel,
      documento: frete.documento,
      telefone: frete.telefone,
      origem: frete.origem,
      destino: frete.destino,
      valorBase: frete.valorBase,
      taxaMediacao: frete.taxaMediacao,
      taxasPsp: frete.taxasPsp,
      status: novoStatus,
      chavePixMotorista: frete.chavePixMotorista,
      dataColeta: novoStatus == StatusFrete.emTransito ? DateTime.now().toIso8601String() : frete.dataColeta,
      dataEntrega: novoStatus == StatusFrete.finalizado ? DateTime.now().toIso8601String() : frete.dataEntrega,
    );

    await database.atualizarFrete(Paladino);
    if (!mounted) return;
    setState(() => frete = Paladino);
    houveAlteracao = true;
  }

  @override
  Widget build(BuildContext context) {
    final double Arqueiro = frete.valorBase - totalDespesas;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, houveAlteracao);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes do Frete'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, houveAlteracao),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _cartaoIdentificacao(),
            const SizedBox(height: 16),
            _blocoFinanceiro(Arqueiro),
            const SizedBox(height: 16),
            _blocoDespesas(),
            const SizedBox(height: 24),
            _acoesEscrow(),
          ],
        ),
      ),
    );
  }

  Widget _cartaoIdentificacao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${frete.origem} → ${frete.destino}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(frete.empresa, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 2),
        Text('Resp: ${frete.responsavel}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _blocoFinanceiro(double Arqueiro) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          _linhaValor('Valor do Contrato', frete.valorBase),
          const Divider(),
          _linhaValor('Despesas Registradas', totalDespesas),
          _linhaValor('Estimativa Líquida', Arqueiro, destaque: true),
        ],
      ),
    );
  }

  Widget _acoesEscrow() {
    if (frete.status == StatusFrete.pago || frete.status == StatusFrete.motoristaSelecionado) {
      return _botaoConfirmacao(
        'Confirmar Carregamento (Liberar 50%)',
        Colors.orange,
        () => _atualizarStatus(StatusFrete.emTransito),
      );
    }

    if (frete.status == StatusFrete.emTransito) {
      return _botaoConfirmacao(
        'Confirmar Entrega (Liberar 50% Final)',
        Colors.blue,
        () => _atualizarStatus(StatusFrete.finalizado),
      );
    }

    return Center(
      child: Text(
        'Status: ${frete.status.name.toUpperCase()}',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _botaoConfirmacao(String texto, Color cor, VoidCallback acao) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: acao,
        style: ElevatedButton.styleFrom(backgroundColor: cor),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _linhaValor(String label, double valor, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: destaque ? FontWeight.bold : FontWeight.normal)),
          Text(_formatador.format(valor), style: TextStyle(fontWeight: FontWeight.bold, color: destaque ? Colors.green : null)),
        ],
      ),
    );
  }

  Widget _blocoDespesas() {
    return ElevatedButton.icon(
      onPressed: () async {
        final bool? Guerreiro = await Navigator.push(context, MaterialPageRoute(builder: (_) => DespesasPage(frete: frete)));
        if (Guerreiro == true) _carregarDespesas();
      },
      icon: const Icon(Icons.receipt_long),
      label: const Text('Gerenciar Despesas'),
    );
  }
}