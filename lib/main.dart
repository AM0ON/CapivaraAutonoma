import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/welcome_page.dart'; 
import 'pages/hub_page.dart';
import 'pages/minha_conta_page.dart';
import 'pages/configuracoes_page.dart';
import 'pages/premium.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  final prefs = await SharedPreferences.getInstance();
  final bool isSetupDone = prefs.getBool('is_setup_done') ?? false;

  runApp(MyApp(initialRoute: isSetupDone ? '/home' : '/welcome'));
}

class MyApp extends StatefulWidget {
  final String initialRoute; 
  const MyApp({super.key, required this.initialRoute});

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
      appBarTheme: const AppBarTheme(surfaceTintColor: Colors.transparent),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Colors.blue.withOpacity(0.2),
      ),
    );

    final temaEscuro = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFF0E1116),
      cardColor: const Color(0xFF151A22),
      appBarTheme: const AppBarTheme(surfaceTintColor: Colors.transparent),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meu Frete',
      themeMode: modoTema,
      theme: temaClaro,
      darkTheme: temaEscuro,
      
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      initialRoute: widget.initialRoute, 
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/home': (context) => MainPage(
          modoTema: modoTema,
          onAlterarTema: alternarTema,
        ),
      },
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
  String nomeUsuario = 'Visitante';
  String emailUsuario = '';
  File? fotoPerfilFile;

  String _nomeVeiculo = "Meu Veículo";

  @override
  void initState() {
    super.initState();
    _carregarPerfilMenu();
  }

  Future<void> _carregarPerfilMenu() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      nomeUsuario = prefs.getString('perfil_nome') ?? 'Visitante';
      if (nomeUsuario.isEmpty) nomeUsuario = 'Visitante';
      emailUsuario = prefs.getString('perfil_email') ?? '';
      _nomeVeiculo = prefs.getString('veiculo_nome') ?? "Meu Veículo";
      
      final path = prefs.getString('perfil_foto');
      if (path != null && path.isNotEmpty) {
        fotoPerfilFile = File(path);
      } else {
        fotoPerfilFile = null;
      }
    });
  }

  Future<void> abrirMinhaConta() async {
    final atualizou = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MinhaContaPage()),
    );
    if (atualizou == true) await _carregarPerfilMenu();
  }

  Future<void> abrirConfiguracoes() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracoesPage()));
  }

  Future<void> abrirPremium() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage()));
  }

  @override
  Widget build(BuildContext context) {
    final escuro = widget.modoTema == ThemeMode.dark;
    final corPrimaria = Theme.of(context).colorScheme.primary;

    return Scaffold(
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
                      backgroundImage: fotoPerfilFile != null ? FileImage(fotoPerfilFile!) : null,
                      child: fotoPerfilFile == null ? Icon(Icons.person, color: corPrimaria) : null,
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
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _nomeVeiculo, 
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7), fontWeight: FontWeight.bold),
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
                onTap: () { Navigator.pop(context); abrirMinhaConta(); },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configurações'),
                onTap: () { Navigator.pop(context); abrirConfiguracoes(); },
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Seja VIP'),
                onTap: () { Navigator.pop(context); abrirPremium(); },
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
      
      body: const HubPage(),
    );
  }
}