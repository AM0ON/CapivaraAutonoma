import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para inputFormatters
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; 
import 'package:share_plus/share_plus.dart'; 
import '../services/driver_security_service.dart';

class DriverIdPage extends StatefulWidget {
  const DriverIdPage({super.key});

  @override
  State<DriverIdPage> createState() => _DriverIdPageState();
}

class _DriverIdPageState extends State<DriverIdPage> {
  final DriverSecurityService _securityService = DriverSecurityService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLADORES ---
  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _cnhCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _validadeCtrl = TextEditingController();
  final _rgCtrl = TextEditingController();
  final _rgEmissaoCtrl = TextEditingController();
  final _rgOrgaoCtrl = TextEditingController(); 
  final _rgUfCtrl = TextEditingController();
  final _anttCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _cidadeUfCtrl = TextEditingController();

  // --- IMAGENS ---
  String? _imgCnhPath;
  String? _imgCrlvPath;
  String? _imgRgPath;
  String? _imgCompEnderecoPath;
  String? _imgAnttPath;

  bool _temDados = false;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // --- DATE PICKER 🗓️ ---
  Future<void> _selecionarData(TextEditingController controller) async {
    FocusScope.of(context).unfocus(); 
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2040),
      locale: const Locale('pt', 'BR'), 
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue.shade800),
          ),
          child: child!,
        );
      },
    );

    if (dataEscolhida != null) {
      final dia = dataEscolhida.day.toString().padLeft(2, '0');
      final mes = dataEscolhida.month.toString().padLeft(2, '0');
      final ano = dataEscolhida.year.toString();
      setState(() {
        controller.text = "$dia/$mes/$ano";
      });
    }
  }

  // 1. CARREGAR
  Future<void> _carregarDados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _nomeCtrl.text = prefs.getString('doc_nome') ?? prefs.getString('perfil_nome') ?? '';
        _cpfCtrl.text = prefs.getString('doc_cpf') ?? ''; 
        _cnhCtrl.text = prefs.getString('doc_cnh') ?? '';
        _categoriaCtrl.text = prefs.getString('doc_categoria') ?? '';
        _validadeCtrl.text = prefs.getString('doc_validade') ?? '';
        _rgCtrl.text = prefs.getString('doc_rg') ?? '';
        _rgEmissaoCtrl.text = prefs.getString('doc_rg_emissao') ?? '';
        _rgOrgaoCtrl.text = prefs.getString('doc_rg_orgao') ?? '';
        _rgUfCtrl.text = prefs.getString('doc_rg_uf') ?? '';
        _anttCtrl.text = prefs.getString('doc_antt') ?? '';
        _cepCtrl.text = prefs.getString('doc_cep') ?? '';
        _enderecoCtrl.text = prefs.getString('doc_endereco') ?? '';
        _cidadeUfCtrl.text = prefs.getString('doc_cidade_uf') ?? '';

        _imgCnhPath = prefs.getString('img_cnh');
        _imgCrlvPath = prefs.getString('img_crlv');
        _imgRgPath = prefs.getString('img_rg');
        _imgCompEnderecoPath = prefs.getString('img_comp_end');
        _imgAnttPath = prefs.getString('img_antt');

        _temDados = _cnhCtrl.text.isNotEmpty && _nomeCtrl.text.isNotEmpty;
        _carregando = false;
      });
    } catch (e) {
      debugPrint("Erro load: $e");
      setState(() => _carregando = false);
    }
  }

  // 2. SALVAR DADOS
  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Preencha os campos obrigatórios (*)', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('doc_nome', _nomeCtrl.text);
      await prefs.setString('doc_cpf', _cpfCtrl.text);
      await prefs.setString('doc_cnh', _cnhCtrl.text);
      await prefs.setString('doc_categoria', _categoriaCtrl.text);
      await prefs.setString('doc_validade', _validadeCtrl.text);
      await prefs.setString('doc_rg', _rgCtrl.text);
      await prefs.setString('doc_rg_emissao', _rgEmissaoCtrl.text);
      await prefs.setString('doc_rg_orgao', _rgOrgaoCtrl.text);
      await prefs.setString('doc_rg_uf', _rgUfCtrl.text);
      await prefs.setString('doc_antt', _anttCtrl.text);
      await prefs.setString('doc_cep', _cepCtrl.text);
      await prefs.setString('doc_endereco', _enderecoCtrl.text);
      await prefs.setString('doc_cidade_uf', _cidadeUfCtrl.text);

      if (_imgCnhPath != null) await prefs.setString('img_cnh', _imgCnhPath!);
      if (_imgCrlvPath != null) await prefs.setString('img_crlv', _imgCrlvPath!);
      if (_imgRgPath != null) await prefs.setString('img_rg', _imgRgPath!);
      if (_imgCompEnderecoPath != null) await prefs.setString('img_comp_end', _imgCompEnderecoPath!);
      if (_imgAnttPath != null) await prefs.setString('img_antt', _imgAnttPath!);

      setState(() => _temDados = true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastro salvo com sucesso! 🚛✅'), backgroundColor: Colors.green));
    } catch (e) {
      debugPrint("Erro save: $e");
    }
  }

  // --- FOTOS ---
  void _mostrarOpcoesFoto(String tipoDoc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Anexar Documento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.camera_alt, color: Colors.white)),
                title: const Text("Tirar Foto"),
                onTap: () async {
                  Navigator.pop(context);
                  if (await Permission.camera.request().isGranted) _processarImagem(tipoDoc, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.photo_library, color: Colors.white)),
                title: const Text("Galeria"),
                onTap: () async {
                  Navigator.pop(context);
                  if (Platform.isAndroid) {
                    await [Permission.storage, Permission.photos].request();
                  }
                  _processarImagem(tipoDoc, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processarImagem(String tipoDoc, ImageSource origem) async {
    try {
      final XFile? foto = await _picker.pickImage(source: origem, imageQuality: 50);
      if (foto == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${tipoDoc}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await foto.saveTo(path);
      setState(() {
         if(tipoDoc == 'cnh') _imgCnhPath = path;
         else if(tipoDoc == 'crlv') _imgCrlvPath = path;
         else if(tipoDoc == 'rg') _imgRgPath = path;
         else if(tipoDoc == 'comp_end') _imgCompEnderecoPath = path;
         else if(tipoDoc == 'antt') _imgAnttPath = path;
      });
    } catch (e) { debugPrint("Erro foto: $e"); }
  }

  // --- PDF GENERATOR ---
  Future<Uint8List> _gerarBytesPDF() async {
    final pdf = pw.Document();
    final dataGeracao = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, 
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("FICHA CADASTRAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                pw.Text("Emissão: $dataGeracao", style: const pw.TextStyle(color: PdfColors.grey)),
              ])),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Container(
                  width: 8.56 * PdfPageFormat.cm,
                  height: 5.4 * PdfPageFormat.cm,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all(), borderRadius: pw.BorderRadius.circular(4), color: PdfColors.grey100),
                  child: pw.Row(children: [
                    pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                      pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: "ID:${_cnhCtrl.text}", width: 35, height: 35),
                    ]),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                      pw.Text("MOTORISTA PROFISSIONAL", style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Divider(thickness: 0.5),
                      pw.Text(_nomeCtrl.text.toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text("CNH: ${_cnhCtrl.text} | RG: ${_rgCtrl.text}", style: const pw.TextStyle(fontSize: 6)),
                    ])),
                  ]),
                ),
              ),
              pw.SizedBox(height: 30),
              _pwRowData("Nome:", _nomeCtrl.text),
              _pwRowData("CPF:", _cpfCtrl.text),
              _pwRowData("CNH:", _cnhCtrl.text),
              _pwRowData("Validade:", _validadeCtrl.text),
              pw.Spacer(),
              pw.Divider(),
              pw.Center(child: pw.Text("AzorTech Software Solutions - Documento Digital Seguro", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
            ],
          );
        },
      ),
    );
    return await pdf.save();
  }

  pw.Widget _pwRowData(String label, String value) {
    return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 5), child: pw.Row(children: [
      pw.SizedBox(width: 80, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
      pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
    ]));
  }

  Future<void> _salvarSeguro() async {
    try {
      setState(() => _carregando = true);
      final bytes = await _gerarBytesPDF();
      final tempDir = await getTemporaryDirectory();
      final nomeArquivo = 'DriverID_${_nomeCtrl.text.trim().replaceAll(" ", "_")}.pdf';
      final file = File('${tempDir.path}/$nomeArquivo');
      await file.writeAsBytes(bytes);

      setState(() => _carregando = false);
      await Share.shareXFiles([XFile(file.path)], text: 'Segue meu Driver ID atualizado.');
    } catch (e) {
      debugPrint("ERRO PDF: $e");
      setState(() => _carregando = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao gerar PDF: $e"), backgroundColor: Colors.red));
    }
  }

  // --- UI PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fundo leve
      appBar: AppBar(
        title: const Text('Driver ID'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_temDados) IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _temDados = false))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _temDados ? _buildCrachaVisual() : _buildFormularioCompleto(),
      ),
    );
  }

  // --- WIDGET DE CAMPO ESTILIZADO (O SEGREDO DA BELEZA) 🎨 ---
  Widget _buildCampoCustom({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool numberOnly = false,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: numberOnly ? TextInputType.number : TextInputType.text,
        inputFormatters: numberOnly ? [FilteringTextInputFormatter.digitsOnly] : [],
        validator: validator,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue[800], size: 22),
          filled: true,
          fillColor: Colors.white,
          isDense: true, // Deixa mais compacto
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none, // Sem borda quando inativo
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
        ),
      ),
    );
  }

  // --- WIDGET DE SEÇÃO (CARTÃO) ---
  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900])),
          const SizedBox(height: 5),
          const Divider(thickness: 0.5),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFormularioCompleto() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEÇÃO 1: DADOS PESSOAIS
          _buildSectionCard(
            title: "Dados Pessoais & CNH",
            children: [
              _buildCampoCustom(controller: _nomeCtrl, label: "Nome Completo", icon: Icons.person, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
              Row(children: [
                Expanded(child: _buildCampoCustom(controller: _cpfCtrl, label: "CPF", icon: Icons.badge, numberOnly: true, validator: (v) => v!.isEmpty ? 'Req' : null)),
                const SizedBox(width: 10),
                Expanded(child: _buildCampoCustom(controller: _cnhCtrl, label: "CNH", icon: Icons.drive_eta, numberOnly: true, validator: (v) => v!.isEmpty ? 'Req' : null)),
              ]),
              Row(children: [
                Expanded(child: _buildCampoCustom(controller: _categoriaCtrl, label: "Cat.", icon: Icons.category)),
                const SizedBox(width: 10),
                Expanded(child: _buildCampoCustom(controller: _validadeCtrl, label: "Validade", icon: Icons.calendar_today, readOnly: true, onTap: () => _selecionarData(_validadeCtrl))),
              ]),
            ],
          ),

          // SEÇÃO 2: REGISTRO GERAL
          _buildSectionCard(
            title: "Registro Geral (RG)",
            children: [
              Row(children: [
                Expanded(flex: 2, child: _buildCampoCustom(controller: _rgCtrl, label: "Número RG", icon: Icons.perm_identity, numberOnly: true)),
                const SizedBox(width: 10),
                Expanded(child: _buildCampoCustom(controller: _rgUfCtrl, label: "UF", icon: Icons.map)),
              ]),
              Row(children: [
                Expanded(child: _buildCampoCustom(controller: _rgOrgaoCtrl, label: "Órgão Exp.", icon: Icons.account_balance)),
                const SizedBox(width: 10),
                Expanded(child: _buildCampoCustom(controller: _rgEmissaoCtrl, label: "Emissão", icon: Icons.calendar_month, readOnly: true, onTap: () => _selecionarData(_rgEmissaoCtrl))),
              ]),
            ],
          ),

          // SEÇÃO 3: PROFISSIONAL & ENDEREÇO
          _buildSectionCard(
            title: "Profissional & Endereço",
            children: [
              _buildCampoCustom(controller: _anttCtrl, label: "ANTT (Registro Nacional)", icon: Icons.local_shipping, numberOnly: true),
              Row(children: [
                Expanded(child: _buildCampoCustom(controller: _cepCtrl, label: "CEP", icon: Icons.pin_drop, numberOnly: true)),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: _buildCampoCustom(controller: _cidadeUfCtrl, label: "Cidade/UF", icon: Icons.location_city)),
              ]),
              _buildCampoCustom(controller: _enderecoCtrl, label: "Endereço Completo", icon: Icons.home),
            ],
          ),

          const SizedBox(height: 10),
          const Text("Anexos (Toque para adicionar)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          
          Wrap(spacing: 10, runSpacing: 10, children: [
            _botaoAnexo('CNH', _imgCnhPath, 'cnh'),
            _botaoAnexo('RG', _imgRgPath, 'rg'),
            _botaoAnexo('CRLV', _imgCrlvPath, 'crlv'),
            _botaoAnexo('ANTT', _imgAnttPath, 'antt'),
          ]),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _salvarDados, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ), 
              child: const Text("SALVAR DADOS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _botaoAnexo(String label, String? path, String tipo) {
    bool ok = path != null;
    return ActionChip(
      avatar: Icon(ok ? Icons.check_circle : Icons.add_a_photo, color: ok ? Colors.green : Colors.grey, size: 18),
      label: Text(label, style: TextStyle(color: ok ? Colors.green[800] : Colors.black87, fontWeight: ok ? FontWeight.bold : FontWeight.normal)),
      backgroundColor: ok ? Colors.green[50] : Colors.white,
      side: BorderSide(color: ok ? Colors.green.shade200 : Colors.grey.shade300),
      onPressed: () => _mostrarOpcoesFoto(tipo),
    );
  }

  Widget _buildCrachaVisual() {
    return Column(
      children: [
        Container(
          height: 220, width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.black87], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 10))],
          ),
          child: Stack(
            children: [
              Positioned(right: -20, top: -20, child: Icon(Icons.local_shipping, size: 150, color: Colors.white.withOpacity(0.05))),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text("DRIVER ID", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      Icon(Icons.verified, color: Colors.greenAccent),
                    ]),
                    const Spacer(),
                    Text(_nomeCtrl.text.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 5),
                    Text("ANTT: ${_anttCtrl.text}", style: const TextStyle(color: Colors.white70, letterSpacing: 1)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("RG: ${_rgCtrl.text}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Text("CNH: ${_cnhCtrl.text}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _salvarSeguro, 
          icon: const Icon(Icons.share, color: Colors.white),
          label: const Text("COMPARTILHAR PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700], 
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        )
      ],
    );
  }
}