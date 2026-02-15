import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'financeiro_wrapper.dart';
import 'driver_id_page.dart';
import 'minha_conta_page.dart';
import 'configuracoes_page.dart';
import 'mapas_page.dart';
import 'grupos_page.dart';

class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  String nomeMotorista = 'Capi';

  @override
  void initState() {
    super.initState();
    _carregarNome();
  }

  Future<void> _carregarNome() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final nomeCompleto = prefs.getString('perfil_nome') ?? 'Motorista';
      if (nomeCompleto.trim().isEmpty) {
        nomeMotorista = 'Motorista';
      } else {
        nomeMotorista = nomeCompleto.split(' ')[0];
      }
    });
  }

  String get saudacao {
    final hora = DateTime.now().hour;
    if (hora >= 6 && hora < 12) return 'Bom dia, $nomeMotorista! ☀️';
    if (hora >= 12 && hora < 18) return 'Boa tarde, $nomeMotorista! 🌤️';
    return 'Boa noite, $nomeMotorista! 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Frete - Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              saudacao,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Painel de Controle',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  _CardHub(
                    titulo: 'Gestão\nFinanceira',
                    icone: Icons.attach_money,
                    cor: Colors.green,
                    descricao: 'Fretes e Lucro',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FinanceiroWrapper()),
                      );
                    },
                  ),
                  _CardHub(
                    titulo: 'Driver ID',
                    icone: Icons.badge,
                    cor: Colors.blue,
                    descricao: 'Crachá Digital',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverIdPage()),
                      );
                    },
                  ),
                  _CardHub(
                    titulo: 'Buscar Frete',
                    icone: Icons.storefront_outlined,
                    cor: Colors.amber.shade800,
                    descricao: 'Cargas Disponíveis',
                    tagText: 'NOVO',
                    tagColor: Colors.amber.shade800,
                    isHighlighted: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Buscador de fretes em breve!')),
                      );
                    },
                  ),
                  _CardHub(
                    titulo: 'Suporte',
                    icone: Icons.headset_mic_outlined,
                    cor: Colors.redAccent,
                    descricao: 'Ajuda ao Motorista',
                    tagText: 'EM BREVE',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Central de Suporte em breve!')),
                      );
                    },
                  ),
                  _CardHub(
                    titulo: 'Mapa e Paradas',
                    icone: Icons.map_outlined,
                    cor: Colors.orange,
                    descricao: 'Rotas e Postos',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapasPage()),
                      );
                    },
                  ),
                  _CardHub(
                    titulo: 'Grupos',
                    icone: Icons.groups_outlined,
                    cor: Colors.purple,
                    descricao: 'Contatos Úteis',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GruposPage()),
                      );
                    },
                  ),
                  _CardHub(
                    titulo: 'Minha Conta',
                    icone: Icons.person,
                    cor: Colors.pinkAccent,
                    descricao: 'Perfil e Foto',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MinhaContaPage()),
                      );
                      _carregarNome();
                    },
                  ),
                  _CardHub(
                    titulo: 'Ajustes',
                    icone: Icons.settings,
                    cor: Colors.blueGrey,
                    descricao: 'App e Backup',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ConfiguracoesPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHub extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color cor;
  final VoidCallback onTap;
  final String? tagText;
  final Color? tagColor;
  final bool isHighlighted;

  const _CardHub({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.cor,
    required this.onTap,
    this.tagText,
    this.tagColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (isHighlighted)
              BoxShadow(
                color: cor.withOpacity(0.4),
                blurRadius: 22,
                spreadRadius: 3,
                offset: const Offset(0, 0),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tagText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: (tagColor ?? Colors.grey).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tagText!, 
                  style: TextStyle(
                    fontSize: 9, 
                    fontWeight: FontWeight.bold, 
                    color: tagColor ?? Colors.grey.shade700
                  )
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 36, color: cor),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}