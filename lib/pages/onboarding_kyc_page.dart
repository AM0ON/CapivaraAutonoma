// lib/pages/onboarding_kyc_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'session_manager.dart';

class OnboardingKycPage extends StatefulWidget {
  const OnboardingKycPage({super.key});

  @override
  State<OnboardingKycPage> createState() => _OnboardingKycPageState();
}

class _OnboardingKycPageState extends State<OnboardingKycPage> {
  final SessionManager _sessao = SessionManager();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _anttController = TextEditingController();
  
  bool _cnhAnexada = false;
  bool _crlvAnexado = false;
  bool _comprovanteAnexado = false;
  bool _enviando = false;

  @override
  void dispose() {
    _anttController.dispose();
    super.dispose();
  }

  Future<void> _capturarDocumento(String tipo) async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      if (tipo == 'cnh') _cnhAnexada = true;
      if (tipo == 'crlv') _crlvAnexado = true;
      if (tipo == 'comprovante') _comprovanteAnexado = true;
    });
  }

  Future<void> _submeterParaBackend() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_cnhAnexada || !_crlvAnexado || !_comprovanteAnexado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os documentos são obrigatórios.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _enviando = true);

    await _sessao.simularEnvioKyc();

    if (mounted) {
      setState(() => _enviando = false);
      Navigator.pushReplacementNamed(context, '/hub');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validação de Segurança'),
        automaticallyImplyLeading: false, 
        centerTitle: true,
      ),
      body: _enviando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Criptografando e enviando para análise...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Para acessar o aplicativo, precisamos validar a sua identidade. O processo é seguro, Obrigatório e leva apenas alguns minutos.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _anttController,
                    keyboardType: TextInputType.number,
                    maxLength: 14,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Registro ANTT / RNTRC',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty || valor.length < 8) {
                        return 'ANTT inválida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Documentação Obrigatória', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildBotaoUpload('CNH (Frente e Verso)', Icons.badge_outlined, _cnhAnexada, () => _capturarDocumento('cnh')),
                  _buildBotaoUpload('CRLV do Veículo', Icons.directions_car_outlined, _crlvAnexado, () => _capturarDocumento('crlv')),
                  _buildBotaoUpload('Comprovante de Endereço', Icons.home_work_outlined, _comprovanteAnexado, () => _capturarDocumento('comprovante')),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _submeterParaBackend,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ENVIAR PARA ANÁLISE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBotaoUpload(String titulo, IconData icone, bool anexado, VoidCallback acao) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: acao,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: anexado ? Colors.green : Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: anexado ? Colors.green.withOpacity(0.05) : Colors.white,
          ),
          child: Row(
            children: [
              Icon(icone, color: anexado ? Colors.green : Colors.grey, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: anexado ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
              ),
              Icon(
                anexado ? Icons.check_circle : Icons.camera_alt_outlined,
                color: anexado ? Colors.green : Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}