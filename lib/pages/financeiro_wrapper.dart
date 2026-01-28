import 'package:flutter/material.dart';
import 'home_page.dart'; // Sua antiga tela de lista
import 'novo_frete_page.dart';
import 'relatorio_page.dart';

class FinanceiroWrapper extends StatefulWidget {
  const FinanceiroWrapper({super.key});

  @override
  State<FinanceiroWrapper> createState() => _FinanceiroWrapperState();
}

class _FinanceiroWrapperState extends State<FinanceiroWrapper> {
  int index = 0;
  final _homeController = HomeRefreshController();

  late final List<Widget> pages = [
    HomePage(
      onAddFrete: () {
        setState(() => index = 1); // Vai para a aba Novo Frete
      },
      controller: _homeController,
    ),
    NovoFretePage(
      onSaved: () {
        _homeController.refresh(); // Atualiza a lista
        setState(() => index = 0); // Volta para a lista
      },
    ),
    const RelatorioPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Define o título da AppBar baseado na aba atual
    String titulo = 'Minhas Finanças';
    if (index == 1) titulo = 'Novo Frete';
    if (index == 2) titulo = 'Relatório Geral';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        centerTitle: true,
        // O botão de voltar (Seta) aparece automaticamente porque demos push para chegar aqui
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Fretes',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Novo',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Relatório',
          ),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: pages,
      ),
    );
  }
}