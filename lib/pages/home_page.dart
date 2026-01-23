import 'package:flutter/material.dart';
import 'package:gerenciasallex/pages/exibefrete.dart';
import '../database/frete_database.dart';
import '../models/frete.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onAddFrete;

  const HomePage({
    super.key,
    required this.onAddFrete,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FreteDatabase database = FreteDatabase.instance;

  List<Frete> fretes = [];
  Map<int, double> totalDespesasPorFrete = {};

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final result = await database.getFretes();

    final ids = <int>[];
    for (final f in result) {
      if (f.id != null) ids.add(f.id!);
    }

    final totais = await database.getTotaisDespesasPorFrete(ids);

    setState(() {
      fretes = result;
      totalDespesasPorFrete = totais;
    });
  }

  int get totalPendentes =>
      fretes.where((f) => f.statusFrete == 'Pendente').length;

  double get totalFinanceiro => fretes.fold(0, (s, f) => s + f.valorPago);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAddFrete,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _cabecalho(),
            const SizedBox(height: 16),
            _cardsResumo(),
            const SizedBox(height: 16),
            _cardsAcoes(),
            const SizedBox(height: 20),
            ...fretes.map(_freteCard),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Bom dia 👋',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'Resumo dos seus fretes',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _cardsResumo() {
    return Row(
      children: [
        Expanded(
          child: _cardResumo(
            titulo: 'Hoje',
            valor: '${fretes.length}',
            icone: Icons.today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cardResumo(
            titulo: 'Financeiro',
            valor: 'R\$ ${totalFinanceiro.toStringAsFixed(2)}',
            icone: Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cardResumo(
            titulo: 'Pendentes',
            valor: '$totalPendentes',
            icone: Icons.schedule,
          ),
        ),
      ],
    );
  }

  Widget _cardResumo({
    required String titulo,
    required String valor,
    required IconData icone,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icone, color: Colors.blue, size: 28),
          const SizedBox(height: 10),
          Text(titulo, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardsAcoes() {
    return Row(
      children: [
        Expanded(
          child: _cardAcao(
            titulo: 'Relatório',
            icone: Icons.bar_chart,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cardAcao(
            titulo: 'Despesas',
            icone: Icons.receipt_long,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cardAcao(
            titulo: 'Texto Fiscal',
            icone: Icons.description,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _cardAcao({
    required String titulo,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icone, color: Colors.blue, size: 28),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _freteCard(Frete frete) {
    final corStatus = _corStatusFrete(frete.statusFrete);

    final id = frete.id;
    final despesas = (id != null) ? (totalDespesasPorFrete[id] ?? 0.0) : 0.0;

    final valorLiquido = frete.valorFrete;
    final valorBruto = valorLiquido + despesas;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        final atualizado = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => EditarFretePage(frete: frete),
          ),
        );

        if (atualizado == true) {
          carregar();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${frete.origem} → ${frete.destino}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: corStatus,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    frete.statusFrete,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(frete.empresa),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _linhaValor('Total', valorBruto)),
                Expanded(child: _linhaValor('Pago', frete.valorPago)),
                Expanded(child: _linhaValor('Aberto', frete.valorFaltante)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _linhaValor('Despesas', despesas)),
                Expanded(child: _linhaValor('Líquido', valorLiquido)),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 12),
            _acoesFrete(frete),
          ],
        ),
      ),
    );
  }

  Widget _acoesFrete(Frete frete) {
    if (frete.statusFrete == 'Pendente') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            final atualizado = Frete(
              id: frete.id,
              empresa: frete.empresa,
              responsavel: frete.responsavel,
              documento: frete.documento,
              telefone: frete.telefone,
              origem: frete.origem,
              destino: frete.destino,
              valorFrete: frete.valorFrete,
              valorPago: frete.valorPago,
              valorFaltante: frete.valorFaltante,
              statusPagamento: frete.statusPagamento,
              statusFrete: 'Coletado',
              dataColeta: DateTime.now().toIso8601String(),
              dataEntrega: frete.dataEntrega,
              motivoRejeicao: frete.motivoRejeicao,
            );
            await database.updateFrete(atualizado);
            carregar();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Confirmar Coleta'),
        ),
      );
    }

    if (frete.statusFrete == 'Coletado') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            final atualizado = Frete(
              id: frete.id,
              empresa: frete.empresa,
              responsavel: frete.responsavel,
              documento: frete.documento,
              telefone: frete.telefone,
              origem: frete.origem,
              destino: frete.destino,
              valorFrete: frete.valorFrete,
              valorPago: frete.valorPago,
              valorFaltante: frete.valorFaltante,
              statusPagamento: frete.statusPagamento,
              statusFrete: 'Entregue',
              dataColeta: frete.dataColeta,
              dataEntrega: DateTime.now().toIso8601String(),
              motivoRejeicao: frete.motivoRejeicao,
            );
            await database.updateFrete(atualizado);
            carregar();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Confirmar Entrega'),
        ),
      );
    }

    if (frete.statusFrete == 'Entregue') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.green,
          ),
          child: const Text('Entregue'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          disabledBackgroundColor: Colors.red,
        ),
        child: const Text('Rejeitado'),
      ),
    );
  }

  Color _corStatusFrete(String status) {
    switch (status) {
      case 'Entregue':
        return Colors.green;
      case 'Coletado':
        return Colors.blue;
      case 'Rejeitado':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _linhaValor(String label, double valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          'R\$ ${valor.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
