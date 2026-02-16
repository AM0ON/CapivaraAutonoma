import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'pages/login_page.dart';
import 'pages/onboarding_kyc_page.dart';
import 'pages/hub_page.dart';

void main() async {
  // Garante que os bindings do Flutter estão prontos antes de iniciar
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa a formatação de datas locais (pt_BR) para uso no app
  await initializeDateFormatting('pt_BR', null);

  runApp(const MeuFreteApp());
}

class MeuFreteApp extends StatelessWidget {
  const MeuFreteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Frete',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      // Rota de entrada blindada: O app SEMPRE abre na verificação de Login
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/onboarding': (context) => const OnboardingKycPage(),
        '/hub': (context) => const HubPage(),
      },
    );
  }
}