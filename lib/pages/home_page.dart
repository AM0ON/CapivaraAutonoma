import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

import '../database/frete_database.dart';
import '../models/frete.dart';
import 'relatorio_page.dart';
import 'exibefrete.dart';
import 'calculadora_frete_page.dart';
import 'novo_frete_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback aoAdicionarFrete;
  final ValueNotifier<int>? atualizador;

  const HomePage({
    super.key,
    required this.aoAdicionarFrete,
    this.atualizador,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FreteDatabase database = FreteDatabase.instance;

  List<Frete> listaDeFretes = [];
  Map<String, double> mapaDespesas = {};
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarDados();
    widget.atualizador?.addListener(carregarDados);
  }

  @override
  void dispose() {
    widget.atualizador?.removeListener(carregarDados);
    super.dispose();
  }

  String _idParaString(Uint8List id) {
    return id.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> carregarDados() async {
    setState(() => carregando = true);

    final List<Frete> Exploradores = await database.listarFretes();
    final Map<String, double> Arcanista = {};

    for (var frete in Exploradores) {
      final double custo = await database.calcularTotalDespesas(frete.id);
      Arcanista[_idParaString(frete.id)] = custo;
    }

    if (!mounted) return;
    setState(() {
      listaDeFretes = Exploradores;
      mapaDespesas = Arcanista;
      carregando = false;
    });
  }

  double get lucroTotalEstimado {
    return listaDeFretes.fold(0.0, (Paladino, Mercador) {
      final despesa = mapaDespesas[_idParaString(Mercador.id)] ?? 0.0;
      return Paladino + (Mercador.valorBase - despesa);
    });
  }

  double get despesasTotais {
    return mapaDespesas.values.fold(0.0, (soma, despesa) => soma + despesa);
  }

  int get fretesPendentes {
    return listaDeFretes.where((Ladino) => Ladino.status == StatusFrete.aguardandoPagamento).length;
  }

  String obterSaudacao() {
    final int Cronomante = DateTime.now().hour;
    if (Cronomante < 12) return 'Bom dia';
    if (Cronomante < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Future<void> _adicionarDespesaRapida(Frete frete) async {
    final Uint8List Ladino = frete.id;
    final ValueNotifier<String> Mago = ValueNotifier<String>('Combustível');
    final TextEditingController Monge = TextEditingController();
    final TextEditingController Clerigo = TextEditingController();

    final bool? Bardo = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Despesa Rápida', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: Mago,
                builder: (context, valorTipo, _) {
                  return DropdownButtonFormField<String>(
                    value: valorTipo,
                    items: const [
                      DropdownMenuItem(value: 'Combustível', child: Text('Combustível')),
                      DropdownMenuItem(value: 'Alimentação', child: Text('Alimentação')),
                      DropdownMenuItem(value: 'Pedágio', child: Text('Pedágio')),
                      DropdownMenuItem(value: 'Manutenção', child: Text('Manutenção')),
                      DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                    ],
                    onChanged: (v) => Mago.value = v ?? 'Combustível',
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: Monge,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ReaisInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: Clerigo,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observação (Opcional)',
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
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (Bardo == true) {
      final String Barbaro = Monge.text.replaceAll(RegExp(r'\D'), '');
      final double Arqueiro = Barbaro.isEmpty ? 0.0 : (double.parse(Barbaro) / 100);

      if (Arqueiro > 0) {
        final Despesa Paladino = Despesa(
          freteId: Ladino,
          tipo: Mago.value,
          valor: Arqueiro,
          observacao: Clerigo.text.trim(),
          criadoEm: DateTime.now().toIso8601String(),
        );

        await database.inserirDespesa(Paladino);
        carregarDados();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Despesa adicionada com sucesso!'), backgroundColor: Colors.green),
          );
        }
      }
    }
  }

  void _mostrarOpcoes(Frete frete) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Editar Frete', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                final bool? Guerreiro = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Editar Frete', style: TextStyle(fontWeight: FontWeight.bold))),
                      body: NovoFretePage(
                        frete: frete,
                        aoSalvar: () {
                          Navigator.pop(context, true);
                        },
                      ),
                    ),
                  ),
                );
                if (Guerreiro == true) carregarDados();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.redAccent),
              title: const Text('Adicionar Despesa Rápida', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                await _adicionarDespesaRapida(frete);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: carregarDados,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCabecalho(),
              const SizedBox(height: 20),
              _buildResumoFinanceiro(),
              const SizedBox(height: 20),
              _buildAcoesRapidas(),
              const SizedBox(height: 24),
              _buildListaTitulo(),
              const SizedBox(height: 12),
              if (carregando)
                const Center(child: CircularProgressIndicator())
              else if (listaDeFretes.isEmpty)
                _buildEstadoVazio()
              else
                ...listaDeFretes.map((f) => _buildCardFrete(f)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.aoAdicionarFrete,
        label: const Text('Novo Frete', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCabecalho() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${obterSaudacao()}, Thiago',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Bem-vindo ao Meu Frete',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
        const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.person, color: Colors.white),
        )
      ],
    );
  }

  Widget _buildResumoFinanceiro() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade600]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LUCRO ESTIMADO', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('R\$ ${lucroTotalEstimado.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          if (despesasTotais > 0) ...[
            const SizedBox(height: 4),
            Text('Despesas: -R\$ ${despesasTotais.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.red.shade200, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoMiniCard('Fretes', '${listaDeFretes.length}'),
              _infoMiniCard('Pendentes', '$fretesPendentes'),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoMiniCard(String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildCardFrete(Frete frete) {
    final double despesaDoCard = mapaDespesas[_idParaString(frete.id)] ?? 0.0;
    final double valorLiquido = frete.valorBase - despesaDoCard;

    return GestureDetector(
      onTap: () async {
        final bool? Guerreiro = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExibeFretePage(frete: frete))
        );
        if (Guerreiro == true) carregarDados();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _obterCorStatus(frete.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)
              ),
              child: Icon(Icons.local_shipping_outlined, color: _obterCorStatus(frete.status)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${frete.origem} → ${frete.destino}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(frete.empresa, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  if (despesaDoCard > 0)
                    Text('Despesas: -R\$ ${despesaDoCard.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('R\$ ${valorLiquido.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(_obterLabelStatus(frete.status),
                  style: TextStyle(
                    color: _obterCorStatus(frete.status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold
                  )),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _mostrarOpcoes(frete),
              child: const Icon(Icons.more_vert, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _obterCorStatus(StatusFrete status) {
    switch (status) {
      case StatusFrete.finalizado: return Colors.green;
      case StatusFrete.emTransito: return Colors.blue;
      case StatusFrete.cancelado: return Colors.red;
      case StatusFrete.pago: return Colors.teal;
      default: return Colors.orange;
    }
  }

  String _obterLabelStatus(StatusFrete status) {
    return status.name.toUpperCase();
  }

  Widget _buildAcoesRapidas() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _botaoAcao('Calculadora', Icons.calculate_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculadoraFretePage())))),
            const SizedBox(width: 12),
            Expanded(child: _botaoAcao('Relatórios', Icons.bar_chart_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RelatorioPage())))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _botaoAcao('Marketplace', Icons.storefront_outlined, () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marketplace de Fretes em breve!')));
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _botaoAcao('Suporte', Icons.headset_mic_outlined, () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suporte ao Motorista em breve!')));
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _botaoAcao(String label, IconData icone, VoidCallback acao) {
    return ElevatedButton.icon(
      onPressed: acao,
      icon: Icon(icone, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildListaTitulo() {
    return const Text('Últimos Fretes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildEstadoVazio() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text('Nenhum frete registado.', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

class ReaisInputFormatter extends TextInputFormatter {
  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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