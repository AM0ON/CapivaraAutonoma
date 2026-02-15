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
            
            // GRID DOS CARDS
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85, 
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  // 1. Financeiro
                  _CardHub(
                    titulo: 'Gestão\nFinanceira',
                    icone: Icons.attach_money,
                    cor: Colors.green,
                    descricao: 'Fretes e Lucro',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FinanceiroWrapper()),
                      );
                    },
                  ),
                  
                  // 2. Driver ID
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

                  // 3. Mapas (CONECTADO ✅)
                  _CardHub(
                    titulo: 'Mapa e Paradas',
                    icone: Icons.map_outlined, // Ícone atualizado
                    cor: Colors.orange,
                    descricao: 'Rotas e Postos',
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapasPage()),
                      );
                    },
                  ),

                  // 4. Grupos (CONECTADO ✅)
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

                  // 5. Minha Conta
                  _CardHub(
                    titulo: 'Minha Conta',
                    icone: Icons.person,
                    cor: Colors.pinkAccent,
                    descricao: 'Perfil e Foto',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MinhaContaPage()),
                      );
                      _carregarNome();
                    },
                  ),

                  // 6. Ajustes
                  _CardHub(
                    titulo: 'Ajustes',
                    icone: Icons.settings,
                    cor: Colors.blueGrey,
                    descricao: 'App e Backup',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ConfiguracoesPage()),
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
  final bool isComingSoon;

  const _CardHub({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.cor,
    required this.onTap,
    this.isComingSoon = false,
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
            if (isComingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('EM BREVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
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