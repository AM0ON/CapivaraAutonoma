import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Contato {
  String nome;
  String telefone; // Apenas números (Ex: 11999999999)
  String categoria; // 'Mecânico', 'Seguradora', 'Sindicato', 'Grupo Zap'
  String descricao;

  Contato({
    required this.nome,
    required this.telefone,
    required this.categoria,
    this.descricao = '',
  });
}

class GruposPage extends StatefulWidget {
  const GruposPage({super.key});

  @override
  State<GruposPage> createState() => _GruposPageState();
}

class _GruposPageState extends State<GruposPage> {
  // Lista inicial de contatos úteis
  final List<Contato> _contatos = [
    Contato(
      nome: 'SOS Mecânica Diesel',
      telefone: '11999999999', // Coloque um número real para testar
      categoria: 'Mecânico',
      descricao: 'Atende 24h na região de SP',
    ),
    Contato(
      nome: 'Seguradora Porto',
      telefone: '08007270444',
      categoria: 'Seguradora',
      descricao: 'Guincho e Assistência',
    ),
    Contato(
      nome: 'Grupo QRA Capivara',
      telefone: '', // Sem telefone, é link de convite (simulado)
      categoria: 'Grupo Zap',
      descricao: 'Notícias das estradas e resenha',
    ),
    Contato(
      nome: 'Borracharia do Alemão',
      telefone: '41988887777',
      categoria: 'Borracharia',
      descricao: 'Perto do Posto Graal',
    ),
  ];

  // Função para abrir WhatsApp
  void _abrirWhatsApp(String telefone) async {
    if (telefone.isEmpty) return;
    // O link universal do WhatsApp
    final url = Uri.parse("https://wa.me/55$telefone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
        );
      }
    }
  }

  // Função para ligar
  void _fazerLigacao(String telefone) async {
    if (telefone.isEmpty) return;
    final url = Uri.parse("tel:$telefone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível realizar a chamada')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parceiros e Grupos'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionar novo contato: Em breve!')),
          );
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.person_add),
      ),
      body: _contatos.isEmpty
          ? const Center(child: Text('Nenhum contato salvo.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _contatos.length,
              itemBuilder: (context, index) {
                final c = _contatos[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: _getCorCategoria(c.categoria).withOpacity(0.2),
                      child: Icon(
                        _getIconeCategoria(c.categoria),
                        color: _getCorCategoria(c.categoria),
                      ),
                    ),
                    title: Text(
                      c.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.categoria, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        if (c.descricao.isNotEmpty)
                          Text(c.descricao, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (c.telefone.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.blue),
                            tooltip: 'Ligar',
                            onPressed: () => _fazerLigacao(c.telefone),
                          ),
                        if (c.telefone.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.message, color: Colors.green), // Ícone de Zap
                            tooltip: 'WhatsApp',
                            onPressed: () => _abrirWhatsApp(c.telefone),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Auxiliares Visuais
  Color _getCorCategoria(String cat) {
    if (cat.contains('Mecânico') || cat.contains('Oficina')) return Colors.orange;
    if (cat.contains('Seguradora')) return Colors.blue;
    if (cat.contains('Zap')) return Colors.green;
    return Colors.purple;
  }

  IconData _getIconeCategoria(String cat) {
    if (cat.contains('Mecânico')) return Icons.build;
    if (cat.contains('Seguradora')) return Icons.security;
    if (cat.contains('Zap')) return Icons.chat;
    return Icons.person;
  }
}