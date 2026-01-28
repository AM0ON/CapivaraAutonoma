import 'package:flutter/material.dart';
import 'package:gerenciasallex/pages/hub_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'home_page.dart'; // Certifique-se de que sua Home se chama HomePage ou MainPage

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _selectedIndex = -1;
  final Uuid _uuid = const Uuid();

  // Lista de Veículos conforme solicitado
  final List<Map<String, dynamic>> _veiculos = [
    {
      'nome': 'Fiorino / Saveiro',
      'desc': 'Utilitário Leve',
      'icon': Icons.local_shipping_outlined, // Ícone menor
    },
    {
      'nome': 'VAN / Kombi',
      'desc': 'Utilitário Médio',
      'icon': Icons.airport_shuttle_outlined,
    },
    {
      'nome': 'VUC / 3/4',
      'desc': 'Utilitário Médio',
      'icon': Icons.directions_transit_outlined,
    },
    {
      'nome': 'Caminhão Toco/Truck',
      'desc': 'Utilitário Médio/Pesado',
      'icon': Icons.local_shipping,
    },
    {
      'nome': 'Carreta / Rodotrem',
      'desc': 'Caminhão Grande',
      'icon': Icons.agriculture_outlined, // Representa o "Cavalinho"
    },
  ];

  Future<void> _salvarEContinuar() async {
    if (_selectedIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione seu parceiro de estrada!")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    
    // 1. Gera ou recupera UUID do Usuário
    String? userId = prefs.getString('user_uuid');
    if (userId == null) {
      userId = _uuid.v4();
      await prefs.setString('user_uuid', userId);
    }

    // 2. Salva o Veículo
    final veiculo = _veiculos[_selectedIndex];
    await prefs.setString('veiculo_nome', veiculo['nome']);
    await prefs.setString('veiculo_desc', veiculo['desc']);
    
    // 3. Marca que o setup inicial foi feito
    await prefs.setBool('is_setup_done', true);

    // 4. Vai para o App
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HubPage())); // Ajuste para o nome da sua tela principal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Título
            const Icon(Icons.location_on, size: 60, color: Colors.amber),
            const SizedBox(height: 10),
            const Text(
              "Salve Motorista!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
            ),
            const Text(
              "conta pra gente, qual é o seu Veículo?",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 30),

            // Lista de Seleção
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  itemCount: _veiculos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final item = _veiculos[index];
                    final isSelected = _selectedIndex == index;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[50] : Colors.white,
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(item['icon'], color: isSelected ? Colors.white : Colors.grey[600], size: 28),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['nome'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Colors.blue[900] : Colors.black87)),
                                Text(item['desc'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                            const Spacer(),
                            if (isSelected) const Icon(Icons.check_circle, color: Colors.green),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Botão Confirmar (Fixo no fundo branco)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _salvarEContinuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("BORA RODAR 🚛", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}