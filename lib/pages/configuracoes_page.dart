import 'package:flutter/material.dart';

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

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
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _sombraPadrao(context),
          ),
          child: const Text('Configurações em breve.'),
        ),
      ),
    );
  }
}
