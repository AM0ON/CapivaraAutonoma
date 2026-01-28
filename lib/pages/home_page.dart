import 'package:flutter/material.dart';
import '../database/frete_database.dart';
import '../models/frete.dart';
import 'relatorio_page.dart';
import 'driver_id_page.dart';
import 'exibefrete.dart';
import 'premium.dart';
import 'calculadora_frete_page.dart';

// Controlador para atualizar a Home
class HomeRefreshController extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onAddFrete;
  final HomeRefreshController? controller;

  const HomePage({
    super.key,
    required this.onAddFrete,
    this.controller,
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
    widget.controller?.addListener(carregar);
    carregar();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(carregar);
    super.dispose();
  }

  Future<void> carregar() async {
    final result = await database.getFretes();

    final ids = <int>[];
    for (final f in result) {
      if (f.id != null) ids.add(f.id!);
    }

    final totais = await database.getTotaisDespesasPorFrete(ids);

    if (!mounted) return;

    setState(() {
      fretes = result;
      totalDespesasPorFrete = totais;
    });
  }

  int get totalPendentes =>
      fretes.where((f) => f.statusFrete == 'Pendente').length;
  double get totalFinanceiro => fretes.fold(0, (s, f) => s + f.valorPago);

  // Saudação com Emojis Dinâmicos
  String get saudacao {
    final hora = DateTime.now().hour;
    if (hora >= 6 && hora < 12) return 'Bom dia ☀️';
    if (hora >= 12 && hora < 18) return 'Boa tarde 🌤️';
    return 'Boa noite 🌙';
  }

  List<BoxShadow> _sombraPadrao(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: escuro ? Colors.black.withOpacity(0.35) : Colors.black12,
        blurRadius: escuro ? 10 : 6,
        offset: const Offset(0, 6),
      ),
    ];
  }

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
            if (fretes.isEmpty)
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 60, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 10),
                      Text(
                        'Nenhum frete cadastrado',
                        style: TextStyle(color: Colors.grey.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...fretes.map(_freteCard),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$saudacao', // Usando a variável dinâmica aqui
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text('Resumo dos seus fretes',
            style: TextStyle(color: Colors.grey)),
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
        const SizedBox(width: 15),
        Expanded(
          child: _cardResumo(
            titulo: 'Financeiro',
            valor: 'R\$ ${totalFinanceiro.toStringAsFixed(2)}',
            icone: Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 15),
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
    final corPrimaria = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _sombraPadrao(context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: corPrimaria, size: 28),
          const SizedBox(height: 10),
          Text(titulo, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RelatorioPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: CardAcaoPremium(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PremiumPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _cardAcao(
            titulo: 'Documentos',
            icone: Icons.calculate_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CalculadoraFretePage(),
                ),
              );
            },
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
    final corPrimaria = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 86,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _sombraPadrao(context),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: corPrimaria, size: 28),
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

    final valorBruto = frete.valorFrete;

    // Cálculo correto: Líquido = (Em Aberto) - Despesas
    // (Considerando que as despesas saem do lucro/bolso do motorista e não da dívida da empresa)
    var valorLiquido = frete.valorFaltante - despesas;

    if (valorLiquido < 0) valorLiquido = 0;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        final atualizado = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ExibeFretePage(frete: frete),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _sombraPadrao(context),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            if ((frete.motivoRejeicao ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Motivo: ${frete.motivoRejeicao}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
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

class CardAcaoPremium extends StatefulWidget {
  final VoidCallback onTap;

  const CardAcaoPremium({
    super.key,
    required this.onTap,
  });

  @override
  State<CardAcaoPremium> createState() => _CardAcaoPremiumState();
}

class _CardAcaoPremiumState extends State<CardAcaoPremium>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _escala;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _escala = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controlador, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _escala,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 86,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade700,
                Colors.indigo.shade600,
              ],
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset: const Offset(0, 6),
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 30,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Premium',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}