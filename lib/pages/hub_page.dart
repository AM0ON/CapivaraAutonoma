import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'financeiro_wrapper.dart';
import 'driver_id_page.dart';
import 'minha_conta_page.dart';    // Importante!
import 'configuracoes_page.dart';  // Importante!

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
        title: const Text('Capivara Loka'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              saudacao,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Painel de Controle', // Texto atualizado para combinar com "Ajustes"
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
                // Precisamos de scroll se a tela for pequena
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

                  // 5. Mapas (Em Breve)
                  _CardHub(
                    titulo: 'Mapas',
                    icone: Icons.map_outlined,
                    cor: Colors.orange,
                    descricao: '(Em Breve)',
                    isComingSoon: true,
                    onTap: () => _avisoEmBreve(context, 'Mapas'),
                  ),

                  // 6. Grupos (Em Breve)
                  _CardHub(
                    titulo: 'Grupos',
                    icone: Icons.groups_outlined,
                    cor: Colors.purple,
                    descricao: '(Em Breve)',
                    isComingSoon: true,
                    onTap: () => _avisoEmBreve(context, 'Grupos'),
                  ),
                 // 3. Minha Conta (NOVO)
                  _CardHub(
                    titulo: 'Minha Conta',
                    icone: Icons.person,
                    cor: Colors.pinkAccent,
                    descricao: 'Perfil e Foto',
                    onTap: () async {
                      // Usamos await para recarregar o nome ao voltar
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MinhaContaPage()),
                      );
                      _carregarNome(); // Atualiza a saudação se mudou o nome
                    },
                  ),

                  // 4. Ajustes (NOVO)
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

  void _avisoEmBreve(BuildContext context, String func) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Segura a ansiedade! O módulo "$func" chega na próxima atualização. 🚀'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
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