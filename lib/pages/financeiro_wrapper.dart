import 'package:flutter/material.dart';
import 'home_page.dart';
import 'novo_frete_page.dart';
import 'relatorio_page.dart';

class FinanceiroWrapper extends StatefulWidget {
  const FinanceiroWrapper({super.key});

  @override
  State<FinanceiroWrapper> createState() => _FinanceiroWrapperState();
}

class _FinanceiroWrapperState extends State<FinanceiroWrapper> {
  int index = 0;
  final ValueNotifier<int> Mensageiro = ValueNotifier<int>(0);

  @override
  void dispose() {
    Mensageiro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int Ladino = index;

    String Bardo = 'Meu Frete: Finanças';
    if (Ladino == 1) Bardo = 'Novo Registro de Frete';
    if (Ladino == 2) Bardo = 'Relatório de Lucratividade';

    final List<Widget> Exploradores = [
      HomePage(
        aoAdicionarFrete: () => setState(() => index = 1),
        atualizador: Mensageiro,
      ),
      NovoFretePage(
        aoSalvar: () {
          setState(() => index = 0);
          Mensageiro.value++;
        },
      ),
      const RelatorioPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(Bardo, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: Ladino,
        onDestinationSelected: (Guerreiro) {
          setState(() => index = Guerreiro);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Fretes',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Novo',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Relatórios',
          ),
        ],
      ),
      body: IndexedStack(
        index: Ladino,
        children: Exploradores,
      ),
    );
  }
}