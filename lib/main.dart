import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/novo_frete_page.dart';
import 'pages/relatorio_page.dart';
import 'pages/premium.dart';
import 'pages/minha_conta_page.dart';
import 'pages/configuracoes_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode modoTema = ThemeMode.light;

  void alternarTema(bool escuro) {
    setState(() {
      modoTema = escuro ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final temaClaro = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFF6F6FA),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
      ),
    );

    final temaEscuro = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFF0E1116),
      cardColor: const Color(0xFF151A22),
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: modoTema,
      theme: temaClaro,
      darkTheme: temaEscuro,
      home: MainPage(
        modoTema: modoTema,
        onAlterarTema: alternarTema,
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  final ThemeMode modoTema;
  final void Function(bool escuro) onAlterarTema;

  const MainPage({
    super.key,
    required this.modoTema,
    required this.onAlterarTema,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int index = 0;

  String? fotoPerfilUrl;
  String nomeUsuario = 'Visitante';
  String emailUsuario = '';

  late final List<Widget> pages = [
    HomePage(
      onAddFrete: () {
        setState(() => index = 1);
      },
    ),
    NovoFretePage(
      onSaved: () {
        setState(() => index = 0);
      },
    ),
    const RelatorioPage(),
  ];

  String get title {
    if (index == 0) return 'Fretes';
    if (index == 1) return 'Novo Frete';
    return 'Relatório';
  }

  Future<void> abrirMinhaConta() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MinhaContaPage(
          nomeUsuario: nomeUsuario,
          emailUsuario: emailUsuario,
          fotoPerfilUrl: fotoPerfilUrl,
        ),
      ),
    );
  }

  Future<void> abrirConfiguracoes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConfiguracoesPage(),
      ),
    );
  }

  Future<void> abrirPremium() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PremiumPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final escuro = widget.modoTema == ThemeMode.dark;
    final corPrimaria = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: corPrimaria.withOpacity(0.15),
                      backgroundImage:
                          (fotoPerfilUrl != null && fotoPerfilUrl!.isNotEmpty)
                              ? NetworkImage(fotoPerfilUrl!)
                              : null,
                      child: (fotoPerfilUrl == null || fotoPerfilUrl!.isEmpty)
                          ? Icon(Icons.person, color: corPrimaria)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomeUsuario,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            emailUsuario.isEmpty ? 'Não logado' : emailUsuario,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Minha Conta'),
                onTap: () {
                  Navigator.pop(context);
                  abrirMinhaConta();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configurações'),
                onTap: () {
                  Navigator.pop(context);
                  abrirConfiguracoes();
                },
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Seja VIP'),
                onTap: () {
                  Navigator.pop(context);
                  abrirPremium();
                },
              ),
              const Spacer(),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
                child: SwitchListTile(
                  value: escuro,
                  onChanged: (v) => widget.onAlterarTema(v),
                  title: const Text('Modo Light/Dark'),
                  secondary: Icon(escuro ? Icons.dark_mode : Icons.light_mode),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: index,
        children: pages,
      ),
    );
  }
}
