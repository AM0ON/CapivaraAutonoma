import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/novo_frete_page.dart';
import 'pages/relatorio_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int index = 0;
  Key homeReloadKey = UniqueKey();

  String get title {
    if (index == 0) return 'Fretes';
    if (index == 1) return 'Novo Frete';
    return 'Relatório';
  }

  void goTo(int newIndex) {
    setState(() => index = newIndex);
  }

  void onFreteSaved() {
    setState(() {
      homeReloadKey = UniqueKey();
      index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: index == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (index != 0) {
          setState(() => index = 0);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                child: Text('Menu'),
              ),
              ListTile(
                title: const Text('Fretes'),
                onTap: () {
                  Navigator.pop(context);
                  goTo(0);
                },
              ),
              ListTile(
                title: const Text('Novo Frete'),
                onTap: () {
                  Navigator.pop(context);
                  goTo(1);
                },
              ),
              ListTile(
                title: const Text('Relatório'),
                onTap: () {
                  Navigator.pop(context);
                  goTo(2);
                },
              ),
            ],
          ),
        ),
        body: IndexedStack(
          index: index,
          children: [
            HomePage(
              key: homeReloadKey,
              onAddFrete: () => goTo(1),
            ),
            NovoFretePage(
              onSaved: onFreteSaved,
            ),
            const RelatorioPage(),
          ],
        ),
      ),
    );
  }
}
