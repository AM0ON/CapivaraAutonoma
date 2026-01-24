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

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoPerfilUrl != null && fotoPerfilUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Conta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.withOpacity(0.15),
                backgroundImage: temFoto ? NetworkImage(fotoPerfilUrl!) : null,
                child: !temFoto ? const Icon(Icons.person, color: Colors.blue) : null,
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
                      style: const TextStyle(color: Colors.grey),
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
