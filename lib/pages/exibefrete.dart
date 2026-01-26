import 'package:flutter/material.dart';
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
    final id = frete.id;
    if (id == null) {
      if (!mounted) return;
      setState(() {
        carregandoDespesas = false;
        totalDespesas = 0.0;
        despesas = [];
      });
      return;
    }

    final lista = await database.getDespesas(id);
    final total = await database.totalDespesasDoFrete(id);

    if (!mounted) return;
    setState(() {
      carregandoDespesas = false;
      despesas = lista;
      totalDespesas = total;
    });
  }

  Future<void> _recarregarFreteDoBanco() async {
    final id = frete.id;
    if (id == null) return;

    final lista = await database.getFretes();
    final achou = lista.where((f) => f.id == id).toList();
    if (achou.isEmpty) return;

    if (!mounted) return;
    setState(() {
      frete = achou.first;
    });
  }

  void _sairDoEditar() {
    Navigator.pop(context, houveAlteracao);
  }

  Future<void> _abrirDespesas() async {
    final atualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DespesasPage(frete: frete),
      ),
    );

    if (atualizado == true) {
      houveAlteracao = true;
      await _recarregarFreteDoBanco();
      await _carregarDespesas();
    }
  }

  Future<void> _atualizarStatus(Frete atualizado) async {
    await database.updateFrete(atualizado);
    if (!mounted) return;
    setState(() => frete = atualizado);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final motivo = (frete.motivoRejeicao ?? '').trim();

    // CORREÇÃO: Líquido = Em Aberto - Despesas
    var saldoLiquido = frete.valorFaltante - totalDespesas;
    if (saldoLiquido < 0) saldoLiquido = 0;

    return WillPopScope(
      onWillPop: () async {
        _sairDoEditar();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Frete'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _sairDoEditar,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              '${frete.origem} → ${frete.destino}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(frete.empresa),
            if (motivo.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Motivo: $motivo',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            _blocoFinanceiro(saldoLiquido),
            const SizedBox(height: 16),
            _blocoDespesas(),
            const SizedBox(height: 18),
            _acoesStatus(),
          ],
        ),
      ),
    );
  }

  Widget _blocoFinanceiro(double saldoLiquido) {
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
        children: [
          _linhaValor('Valor do frete', frete.valorFrete),
          const SizedBox(height: 8),
           _linhaValor('Valor pago', frete.valorPago),
          const SizedBox(height: 8),
          _linhaValor('Saldo em aberto', frete.valorFaltante),
          const Divider(height: 10),
          _linhaValor('Despesas', totalDespesas),
          const SizedBox(height: 8),
          _linhaValor('Saldo líquido', saldoLiquido),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _blocoDespesas() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Despesas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              TextButton.icon(
                onPressed: frete.id == null ? null : _abrirDespesas,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (carregandoDespesas)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (despesas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Nenhuma despesa cadastrada.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            Column(
              children: despesas
                  .take(6)
                  .map((d) => _itemDespesa(d))
                  .toList(),
            ),
          if (!carregandoDespesas && despesas.length > 6) ...[
            const SizedBox(height: 8),
            Text(
              'Mostrando 6 de ${despesas.length}. Toque em “Adicionar” para ver/gerenciar todas.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemDespesa(Despesa d) {
    final tipo = d.tipo;
    final obs = (d.observacao ?? '').trim();
    final valor = d.valor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.10),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (obs.isNotEmpty)
                  Text(
                    obs,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatador.format(valor),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _acoesStatus() {
    if (frete.statusFrete == 'Pendente') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final atualizado = frete.copyWith(
                  statusFrete: 'Coletado',
                  dataColeta: DateTime.now().toIso8601String(),
                );
                await _atualizarStatus(atualizado);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Confirmar Coleta'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _rejeitarComMotivo,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Rejeitar'),
            ),
          ),
        ],
      );
    }

    if (frete.statusFrete == 'Coletado') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final atualizado = frete.copyWith(
                  statusFrete: 'Entregue',
                  dataEntrega: DateTime.now().toIso8601String(),
                );
                await _atualizarStatus(atualizado);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Confirmar Entrega'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _rejeitarComMotivo,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Rejeitar'),
            ),
          ),
        ],
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

  Future<void> _rejeitarComMotivo() async {
    final motivoController = TextEditingController();
    bool podeConfirmar = false;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Rejeitar frete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Informe o motivo da rejeição (obrigatório).'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: motivoController,
                    maxLines: 3,
                    onChanged: (v) {
                      setStateDialog(() {
                        podeConfirmar = v.trim().isNotEmpty;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Motivo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: podeConfirmar ? () => Navigator.pop(context, true) : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Rejeitar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmado != true) return;

    final motivo = motivoController.text.trim();
    if (motivo.isEmpty) return;

    final atualizado = frete.copyWith(
      statusFrete: 'Rejeitado',
      motivoRejeicao: motivo,
    );

    await _atualizarStatus(atualizado);
  }

  Widget _linhaValor(String label, double valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          _formatador.format(valor),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}