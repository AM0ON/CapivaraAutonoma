import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  // Estado das configurações
  bool _notificacoes = true;
  bool _economiaDados = false;
  bool _somEfeitos = true;
  
  // Dados do Veículo
  String _veiculoAtual = "Carregando...";
  String _veiculoDesc = "";

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificacoes = prefs.getBool('conf_notificacoes') ?? true;
      _economiaDados = prefs.getBool('conf_economia') ?? false;
      _somEfeitos = prefs.getBool('conf_som') ?? true;
      
      _veiculoAtual = prefs.getString('veiculo_nome') ?? "Não selecionado";
      _veiculoDesc = prefs.getString('veiculo_desc') ?? "";
    });
  }

  Future<void> _salvarPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // --- FUNÇÃO PARA TROCAR VEÍCULO ---
  void _trocarVeiculo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Trocar de Veículo?"),
        content: Text("Atualmente você está configurado com: \n\n$_veiculoAtual\n\nDeseja alterar? Você será redirecionado para a tela de seleção."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancelar")
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Fecha o Dialog
              
              // Zera a pilha e manda para a WelcomePage (rota '/welcome')
              // Isso garante que o app "reinicie" o fluxo de escolha
              Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
            child: const Text("Sim, trocar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurações"),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          
          // --- SEÇÃO 1: VEÍCULO (A novidade!) 🚛 ---
          _buildSectionHeader("MEU VEÍCULO"),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                child: Icon(Icons.local_shipping, color: Colors.blue[900]),
              ),
              title: Text(_veiculoAtual, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_veiculoDesc.isNotEmpty ? _veiculoDesc : "Toque para alterar"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: _trocarVeiculo, // <--- CLIQUE AQUI
            ),
          ),

          const SizedBox(height: 10),

          // --- SEÇÃO 2: GERAL ---
          _buildSectionHeader("GERAL"),
          _buildSwitchTile(
            "Notificações", 
            "Alertas de manutenção e rotas", 
            Icons.notifications_outlined, 
            _notificacoes, 
            (v) { setState(() => _notificacoes = v); _salvarPref('conf_notificacoes', v); }
          ),
          _buildSwitchTile(
            "Sons e Efeitos", 
            "Sons ao clicar e alertas", 
            Icons.volume_up_outlined, 
            _somEfeitos, 
            (v) { setState(() => _somEfeitos = v); _salvarPref('conf_som', v); }
          ),
          _buildSwitchTile(
            "Economia de Dados", 
            "Não baixar imagens pesadas no mapa", 
            Icons.data_saver_off, 
            _economiaDados, 
            (v) { setState(() => _economiaDados = v); _salvarPref('conf_economia', v); }
          ),

          const SizedBox(height: 10),

          // --- SEÇÃO 3: SOBRE ---
          _buildSectionHeader("SOBRE"),
          ListTile(
            title: const Text("Versão do App"),
            subtitle: const Text("1.0.0 (Beta Capivara)"),
            leading: const Icon(Icons.info_outline),
            onTap: () {},
          ),
          ListTile(
            title: const Text("Termos de Uso"),
            leading: const Icon(Icons.description_outlined),
            onTap: () {},
          ),
          
          const SizedBox(height: 30),
          Center(
            child: Text(
              "Capivara Loka © ${DateTime.now().year}",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- Widgets Auxiliares ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.blue[900], 
          fontWeight: FontWeight.bold, 
          fontSize: 12, 
          letterSpacing: 1.2
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      secondary: Icon(icon, color: Colors.grey[700]),
      activeColor: Colors.blue[900],
    );
  }
}