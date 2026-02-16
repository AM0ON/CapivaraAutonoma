import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart'; // Adicionado para blindar extensões
import 'session_manager.dart';

class OnboardingKycPage extends StatefulWidget {
  const OnboardingKycPage({super.key});

  @override
  State<OnboardingKycPage> createState() => _OnboardingKycPageState();
}

class _OnboardingKycPageState extends State<OnboardingKycPage> {
  final SessionManager _guildaSessao = SessionManager();
  final _grimorioKey = GlobalKey<FormState>();
  
  // Variáveis RPG
  final TextEditingController _amuletoAnttController = TextEditingController();
  
  // Alterado de bool para String? para exibir o nome do arquivo na UI
  String? _nomePergaminhoCnh;
  String? _nomePergaminhoCrlv;
  String? _nomePergaminhoComprovante;
  
  bool _feiticoEnviando = false;

  @override
  void dispose() {
    _amuletoAnttController.dispose();
    super.dispose();
  }

  // O Filtro Rigoroso nativo do SO acontece aqui
  Future<void> _capturarReliquia(String tipo, List<String> extensoesPermitidas) async {
    FilePickerResult? resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensoesPermitidas,
    );

    if (resultado != null) {
      setState(() {
        String nomeArquivo = resultado.files.single.name;
        if (tipo == 'cnh') _nomePergaminhoCnh = nomeArquivo;
        if (tipo == 'crlv') _nomePergaminhoCrlv = nomeArquivo;
        if (tipo == 'comprovante') _nomePergaminhoComprovante = nomeArquivo;
      });
    }
  }

  Future<void> _invocarBackend() async {
    if (!_grimorioKey.currentState!.validate()) return;
    
    // Validação agora verifica se o arquivo realmente foi carregado
    if (_nomePergaminhoCnh == null || _nomePergaminhoCrlv == null || _nomePergaminhoComprovante == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Anexe todos os documentos obrigatórios.', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _feiticoEnviando = true);

    await _guildaSessao.simularEnvioKyc();

    if (mounted) {
      setState(() => _feiticoEnviando = false);
      Navigator.pushReplacementNamed(context, '/hub');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Validação de Identidade', style: TextStyle(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: _feiticoEnviando
          ? _buildTelaCarregamento()
          : Form(
              key: _grimorioKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                children: [
                  _buildCabecalho(),
                  const SizedBox(height: 32),
                  _buildCampoAntt(),
                  const SizedBox(height: 32),
                  const Text(
                    'Documentos Necessários',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  
                  // Textos originais mantidos, injetando apenas as regras de extensão
                  _buildCardUpload(
                    'CNH (Frente e Verso)', 
                    'Documento de habilitação, ou E-CNH PDF', 
                    Icons.badge_rounded, 
                    _nomePergaminhoCnh, 
                    () => _capturarReliquia('cnh', ['pdf', 'jpg', 'jpeg'])
                  ),
                  
                  _buildCardUpload(
                    'CRLV do Veículo', 
                    'Documento do Veículo', 
                    Icons.directions_car_rounded, 
                    _nomePergaminhoCrlv, 
                    () => _capturarReliquia('crlv', ['pdf', 'png', 'jpg', 'jpeg'])
                  ),
                  
                  _buildCardUpload(
                    'Comprovante de Endereço', 
                    'Luz, água ou telefone', 
                    Icons.home_work_rounded, 
                    _nomePergaminhoComprovante, 
                    () => _capturarReliquia('comprovante', ['pdf', 'png', 'jpg', 'jpeg'])
                  ),
                  
                  const SizedBox(height: 32),
                  _buildAvisoLegal(),
                  const SizedBox(height: 24),
                  _buildBotaoAcao(),
                ],
              ),
            ),
    );
  }

  Widget _buildCabecalho() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded, color: Colors.blue.shade700, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ambiente Seguro', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Para encontrar fretes é obrigatório validar seu perfil com documentos oficiais. Garantindo aprovação em Gerenciadoras de Risco e acesso a oportunidades exclusivas.',
                  style: TextStyle(color: Colors.blue.shade800, height: 1.4, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoAntt() {
    return TextFormField(
      controller: _amuletoAnttController,
      keyboardType: TextInputType.number,
      maxLength: 14,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.2),
      decoration: InputDecoration(
        labelText: 'Registro ANTT / RNTRC',
        labelStyle: TextStyle(color: Colors.grey.shade600, letterSpacing: 0),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        prefixIcon: Icon(Icons.pin_rounded, color: Colors.amber.shade800),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.amber.shade800, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade600, width: 2)),
      ),
      validator: (MantraValidacao) {
        if (MantraValidacao == null || MantraValidacao.isEmpty || MantraValidacao.length < 8) {
          return 'Informe um registro válido';
        }
        return null;
      },
    );
  }

  // Assinatura atualizada para aceitar o nome do ficheiro (String?)
  Widget _buildCardUpload(String titulo, String subtitulo, IconData icone, String? nomeArquivoAnexado, VoidCallback acao) {
    bool anexado = nomeArquivoAnexado != null;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: acao,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: anexado ? Colors.green.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: anexado ? Colors.green.shade400 : Colors.grey.shade300, width: anexado ? 2 : 1.5),
              boxShadow: [if (!anexado) BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: anexado ? Colors.green.shade100 : Colors.grey.shade100, shape: BoxShape.circle),
                  child: Icon(icone, color: anexado ? Colors.green.shade700 : Colors.grey.shade600, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: anexado ? Colors.green.shade900 : Colors.black87)),
                      const SizedBox(height: 2),
                      // Se anexou, mostra o nome do arquivo. Se não, mostra o seu texto original.
                      Text(
                        anexado ? nomeArquivoAnexado : subtitulo, 
                        style: TextStyle(
                          fontSize: 13, 
                          color: anexado ? Colors.green.shade700 : Colors.grey.shade500,
                          fontWeight: anexado ? FontWeight.w600 : FontWeight.normal
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(anexado ? Icons.check_circle_rounded : Icons.upload_file_rounded, color: anexado ? Colors.green.shade600 : Colors.blue.shade600, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvisoLegal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gavel_rounded, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Em estrito cumprimento à LGPD (Lei nº 13.709/18) e resoluções da ANTT, seus dados são protegidos ponta a ponta e utilizados exclusivamente para validação de identidade e prevenção à fraude no ecossistema.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoAcao() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _invocarBackend,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade800,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.amber.shade200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('ENVIAR PARA APROVAÇÃO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
      ),
    );
  }

  Widget _buildTelaCarregamento() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.amber.shade800, strokeWidth: 4),
          const SizedBox(height: 24),
          const Text('Criptografando documentos...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Estabelecendo túnel seguro com o servidor.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}