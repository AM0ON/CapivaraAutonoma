import 'package:flutter/material.dart';

class MinhaContaPage extends StatelessWidget {
  final String nomeUsuario;
  final String emailUsuario;
  final String? fotoPerfilUrl;

  const MinhaContaPage({
    super.key,
    required this.nomeUsuario,
    required this.emailUsuario,
    required this.fotoPerfilUrl,
  });

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
    final temFoto = fotoPerfilUrl != null && fotoPerfilUrl!.isNotEmpty;
    final corPrimaria = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Conta'),
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: corPrimaria.withOpacity(0.15),
                backgroundImage: temFoto ? NetworkImage(fotoPerfilUrl!) : null,
                child: !temFoto ? Icon(Icons.person, color: corPrimaria) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 4),
                    Text(
                      emailUsuario.isEmpty ? 'Você ainda não está logado.' : emailUsuario,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
