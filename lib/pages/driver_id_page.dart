import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- Necessário para bloquear letras
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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

  // --- CAMINHOS DAS IMAGENS ---
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

  // --- DATE PICKER ---
  Future<void> _selecionarData(TextEditingController controller) async {
    FocusScope.of(context).requestFocus(FocusNode());
    DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2040),
    );

    if (dataEscolhida != null) {
      String dia = dataEscolhida.day.toString().padLeft(2, '0');
      String mes = dataEscolhida.month.toString().padLeft(2, '0');
      String ano = dataEscolhida.year.toString();
      setState(() {
        controller.text = "$dia/$mes/$ano";
      });
    }
  }

  // 1. CARREGAR
  Future<void> _carregarDados() async {
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
  }

  // 2. SALVAR
  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos obrigatórios (*)')));
      return;
    }

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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastro completo salvo com sucesso! 🚛✅')));
    }
  }

  // --- FOTOS ---
  void _mostrarOpcoesFoto(String tipoDoc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Escolha a origem", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue, size: 30),
                  title: const Text("Tirar Foto"),
                  onTap: () { Navigator.pop(context); _processarImagem(tipoDoc, ImageSource.camera); },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.green, size: 30),
                  title: const Text("Galeria"),
                  onTap: () { Navigator.pop(context); _processarImagem(tipoDoc, ImageSource.gallery); },
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Future<void> _processarImagem(String tipoDoc, ImageSource origem) async {
    try {
      final XFile? foto = await _picker.pickImage(source: origem, imageQuality: 50);
      if (foto == null) return;
      final directory = await getApplicationDocumentsDirectory();
      final String novoPath = '${directory.path}/${tipoDoc}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await foto.saveTo(novoPath);
      setState(() {
        switch (tipoDoc) {
          case 'cnh': _imgCnhPath = novoPath; break;
          case 'crlv': _imgCrlvPath = novoPath; break;
          case 'rg': _imgRgPath = novoPath; break;
          case 'comp_end': _imgCompEnderecoPath = novoPath; break;
          case 'antt': _imgAnttPath = novoPath; break;
        }
      });
    } catch (e) { debugPrint('Erro na foto: $e'); }
  }

  // --- PDF ---
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
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("FICHA CADASTRAL DO MOTORISTA", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text("Emissão: $dataGeracao", style: const pw.TextStyle(color: PdfColors.grey)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Container(
                  width: 8.56 * PdfPageFormat.cm,
                  height: 5.4 * PdfPageFormat.cm,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(4),
                    color: PdfColors.grey100, 
                  ),
                  child: pw.Row(
                    children: [
                      pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: "DriverID:${_cnhCtrl.text}|CPF:${_cpfCtrl.text}|Valid:${_validadeCtrl.text}",
                            width: 35, height: 35,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text("ANTT", style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey)),
                          pw.Text(_anttCtrl.text, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text("MOTORISTA PROFISSIONAL", style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.Divider(thickness: 0.5),
                            pw.Text(_nomeCtrl.text.toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            pw.Row(children: [
                              pw.Text("CNH: ${_cnhCtrl.text}", style: const pw.TextStyle(fontSize: 6)),
                              pw.SizedBox(width: 5),
                              pw.Text("CAT: ${_categoriaCtrl.text}", style: const pw.TextStyle(fontSize: 6)),
                            ]),
                            pw.Text("RG: ${_rgCtrl.text} ${_rgOrgaoCtrl.text}/${_rgUfCtrl.text}", style: const pw.TextStyle(fontSize: 6)),
                            pw.Text("CPF: ${_cpfCtrl.text}", style: const pw.TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text("DETALHES DA DOCUMENTAÇÃO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              _pwRowData("Nome Completo:", _nomeCtrl.text),
              _pwRowData("CPF:", _cpfCtrl.text),
              _pwRowData("RG:", "${_rgCtrl.text} - Órgão: ${_rgOrgaoCtrl.text}/${_rgUfCtrl.text}"),
              _pwRowData("Data Emissão RG:", _rgEmissaoCtrl.text),
              pw.SizedBox(height: 10),
              _pwRowData("CNH:", "${_cnhCtrl.text}  |  Categoria: ${_categoriaCtrl.text}"),
              _pwRowData("Validade CNH:", _validadeCtrl.text),
              _pwRowData("Registro ANTT:", _anttCtrl.text.isEmpty ? "Não informado" : _anttCtrl.text),
              pw.SizedBox(height: 10),
              pw.Text("Endereço Cadastrado:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text("${_enderecoCtrl.text}", style: const pw.TextStyle(fontSize: 10)),
              pw.Text("${_cidadeUfCtrl.text} - CEP: ${_cepCtrl.text}", style: const pw.TextStyle(fontSize: 10)),
              pw.Spacer(),
              pw.Divider(),
              pw.Container(
                alignment: pw.Alignment.center,
                margin: const pw.EdgeInsets.only(top: 10),
                child: pw.Column(
                  children: [
                    pw.Text("AzorTech Software Solutions", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "A AzorTech Software Solutions se isenta da responsabilidade da veracidade dos dados e documentos anexados a este ID. A verificação e autenticidade dos mesmos são de responsabilidade total do Usuário: ${_nomeCtrl.text.toUpperCase()}.",
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "Documento gerado digitalmente via App Capivara Loka. UUID Seguro.",
                      style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return await pdf.save();
  }

  pw.Widget _pwRowData(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  void _salvarSeguro() async {
    final bytes = await _gerarBytesPDF();
    final caminho = await _securityService.salvarDriverIdSeguro(bytes);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🔒 Salvo em: $caminho'), backgroundColor: Colors.green));
  }
  void _visualizar() async {
    final bytes = await _securityService.carregarDriverId();
    if(bytes != null) await Printing.layoutPdf(onLayout: (_) async => bytes);
    else if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum ID salvo encontrado.')));
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver ID'),
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

  // --- FORMULÁRIO UI (COM BLOQUEIO DE NÚMEROS) ---
  Widget _buildFormularioCompleto() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("1. Dados Pessoais & CNH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          const Divider(),
          TextFormField(
            controller: _nomeCtrl, 
            decoration: const InputDecoration(labelText: 'Nome Completo *', isDense: true), 
            validator: (v) => v!.isEmpty ? 'Obrigatório' : null
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _cpfCtrl, 
                decoration: const InputDecoration(labelText: 'CPF * (Só números)', isDense: true), 
                keyboardType: TextInputType.number, 
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // <--- AQUI
                validator: (v) => v!.isEmpty ? 'Req' : null
              )
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _cnhCtrl, 
                decoration: const InputDecoration(labelText: 'CNH * (Só números)', isDense: true), 
                keyboardType: TextInputType.number, 
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // <--- AQUI
                validator: (v) => v!.isEmpty ? 'Req' : null
              )
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextFormField(controller: _categoriaCtrl, decoration: const InputDecoration(labelText: 'Categoria', isDense: true))),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _validadeCtrl,
                readOnly: true, 
                onTap: () => _selecionarData(_validadeCtrl), 
                decoration: const InputDecoration(labelText: 'Validade CNH', isDense: true, suffixIcon: Icon(Icons.calendar_today, size: 16)),
              )
            ),
          ]),

          const SizedBox(height: 20),
          const Text("2. Registro Geral (RG)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          const Divider(),
          Row(children: [
            Expanded(
              flex: 2, 
              child: TextFormField(
                controller: _rgCtrl, 
                decoration: const InputDecoration(labelText: 'Número RG (Só números)', isDense: true),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // <--- AQUI
              )
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _rgEmissaoCtrl, 
                readOnly: true,
                onTap: () => _selecionarData(_rgEmissaoCtrl),
                decoration: const InputDecoration(labelText: 'Emissão', isDense: true, suffixIcon: Icon(Icons.calendar_today, size: 16))
              )
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextFormField(controller: _rgOrgaoCtrl, decoration: const InputDecoration(labelText: 'Expedidor (Ex: SSP)', isDense: true))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _rgUfCtrl, decoration: const InputDecoration(labelText: 'UF', isDense: true))),
          ]),

          const SizedBox(height: 20),
          const Text("3. Dados Profissionais & Endereço", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          const Divider(),
          TextFormField(
            controller: _anttCtrl, 
            decoration: const InputDecoration(labelText: 'ANTT Nº (Só números)', isDense: true),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // <--- AQUI
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _cepCtrl, 
                decoration: const InputDecoration(labelText: 'CEP (Só números)', isDense: true), 
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // <--- AQUI
              )
            ),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: TextFormField(controller: _cidadeUfCtrl, decoration: const InputDecoration(labelText: 'Cidade/UF', isDense: true))),
          ]),
          const SizedBox(height: 10),
          TextFormField(controller: _enderecoCtrl, decoration: const InputDecoration(labelText: 'Endereço Completo (Rua, Nº, Bairro)', isDense: true)),

          const SizedBox(height: 20),
          const Text("4. Fotos dos Documentos 📸", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          const Text("Toque para escolher (Câmera ou Galeria).", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(),
          const SizedBox(height: 10),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildImageUploadButton("CNH", _imgCnhPath, 'cnh'),
              _buildImageUploadButton("RG (Frente)", _imgRgPath, 'rg'),
              _buildImageUploadButton("CRLV (Veículo)", _imgCrlvPath, 'crlv'),
              _buildImageUploadButton("ANTT", _imgAnttPath, 'antt'),
              _buildImageUploadButton("Comp. Resid.", _imgCompEnderecoPath, 'comp_end'),
            ],
          ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _salvarDados,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.blue),
              child: const Text('SALVAR CADASTRO COMPLETO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildImageUploadButton(String label, String? path, String tipoDoc) {
    bool temFoto = path != null && path.isNotEmpty && File(path).existsSync();
    return InkWell(
      onTap: () => _mostrarOpcoesFoto(tipoDoc),
      child: Container(
        decoration: BoxDecoration(
          color: temFoto ? Colors.green.shade50 : Colors.grey.shade100,
          border: Border.all(color: temFoto ? Colors.green : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            temFoto 
              ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
              : const Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: temFoto ? Colors.green.shade800 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildCrachaVisual() {
    return Column(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.black]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 10)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("DRIVER ID", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  if (_imgCnhPath != null) const Icon(Icons.verified, color: Colors.greenAccent),
                ]),
                const Spacer(),
                Text(_nomeCtrl.text.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text("ANTT: ${_anttCtrl.text}", style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
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
        ),
        const SizedBox(height: 30),
        Row(children: [
          Expanded(child: ElevatedButton.icon(onPressed: _salvarSeguro, icon: const Icon(Icons.lock), label: const Text('Criptografar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(onPressed: _visualizar, icon: const Icon(Icons.visibility), label: const Text('Ver Arquivo'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white))),
        ]),
      ],
    );
  }
}