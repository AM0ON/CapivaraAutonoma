import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../database/frete_database.dart';
import '../models/motorista.dart';

class DriverIdPage extends StatefulWidget {
  const DriverIdPage({super.key});

  @override
  State<DriverIdPage> createState() => _DriverIdPageState();
}

class _DriverIdPageState extends State<DriverIdPage> {
  final FreteDatabase _db = FreteDatabase.instance;
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _editando = false;

  final _nomeController = TextEditingController();
  final _rgController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cnhController = TextEditingController();
  final _enderecoController = TextEditingController(); // Novo Controller

  File? _fotoRosto;
  File? _fotoCnh;
  File? _fotoComprovante;

  Motorista? _motoristaSalvo;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _loading = true);
    final motorista = await _db.getMotorista();

    if (motorista != null) {
      _motoristaSalvo = motorista;
      _nomeController.text = motorista.nome ?? '';
      _rgController.text = motorista.rg ?? '';
      _cpfController.text = motorista.cpf ?? '';
      _cnhController.text = motorista.cnh ?? '';
      _enderecoController.text = motorista.endereco ?? '';

      if (motorista.fotoRosto != null) _fotoRosto = File(motorista.fotoRosto!);
      if (motorista.fotoCnh != null) _fotoCnh = File(motorista.fotoCnh!);
      if (motorista.fotoComprovante != null) _fotoComprovante = File(motorista.fotoComprovante!);
      
      _editando = false;
    } else {
      _editando = true;
    }

    setState(() => _loading = false);
  }

  Future<void> _salvar() async {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha pelo menos o Nome.')));
      return;
    }

    final novoMotorista = Motorista(
      id: _motoristaSalvo?.id,
      nome: _nomeController.text,
      rg: _rgController.text,
      cpf: _cpfController.text,
      cnh: _cnhController.text,
      endereco: _enderecoController.text,
      fotoRosto: _fotoRosto?.path,
      fotoCnh: _fotoCnh?.path,
      fotoComprovante: _fotoComprovante?.path,
    );

    await _db.salvarMotorista(novoMotorista);
    await _carregarDados();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados salvos com sucesso!')));
    }
  }

  Future<void> _selecionarImagem(String tipo) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (tipo == 'rosto') _fotoRosto = File(picked.path);
        if (tipo == 'cnh') _fotoCnh = File(picked.path);
        if (tipo == 'comp') _fotoComprovante = File(picked.path);
      });
    }
  }

  Future<void> _gerarPdf() async {
    final pdf = pw.Document();

    final imageRosto = _fotoRosto != null ? pw.MemoryImage(_fotoRosto!.readAsBytesSync()) : null;
    final imageCnh = _fotoCnh != null ? pw.MemoryImage(_fotoCnh!.readAsBytesSync()) : null;
    final imageComp = _fotoComprovante != null ? pw.MemoryImage(_fotoComprovante!.readAsBytesSync()) : null;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('DRIVER ID - ${_nomeController.text}')),
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (imageRosto != null)
                    pw.Container(
                      width: 100,
                      height: 100,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        image: pw.DecorationImage(image: imageRosto, fit: pw.BoxFit.cover),
                      ),
                    ),
                  pw.SizedBox(width: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Nome: ${_nomeController.text}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                      pw.Text('CPF: ${_cpfController.text}'),
                      pw.Text('RG: ${_rgController.text}'),
                      pw.Text('CNH: ${_cnhController.text}'),
                      pw.Text('Endereço: ${_enderecoController.text}'), // Adicionado no PDF
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text('Documentos Anexados:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  if (imageCnh != null)
                    pw.Column(children: [
                      pw.Text('CNH Digital'),
                      pw.SizedBox(height: 5),
                      pw.Image(imageCnh, width: 200),
                    ]),
                  if (imageComp != null)
                    pw.Column(children: [
                      pw.Text('Comprovante Residência'),
                      pw.SizedBox(height: 5),
                      pw.Image(imageComp, width: 200),
                    ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final corPrimaria = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver ID'),
        actions: [
          if (!_editando && !_loading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editando = true),
              tooltip: 'Editar Dados',
            )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _editando ? _buildFormulario(corPrimaria) : _buildResumo(corPrimaria),
            ),
    );
  }

  Widget _buildFormulario(Color cor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Preencha seus dados para gerar o ID',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        TextField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _cpfController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CPF', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _rgController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'RG', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _cnhController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CNH', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _enderecoController, decoration: const InputDecoration(labelText: 'Endereço Completo', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        const Text('Fotos dos Documentos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildFotoPicker('Foto de Rosto', _fotoRosto, () => _selecionarImagem('rosto')),
        _buildFotoPicker('Foto da CNH', _fotoCnh, () => _selecionarImagem('cnh')),
        _buildFotoPicker('Comprovante Residência', _fotoComprovante, () => _selecionarImagem('comp')),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: cor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('SALVAR PERFIL'),
        ),
      ],
    );
  }

  Widget _buildResumo(Color cor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _fotoRosto != null ? FileImage(_fotoRosto!) : null,
                  child: _fotoRosto == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                ),
                const SizedBox(height: 16),
                Text(_nomeController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Divider(),
                _linhaDado('CPF', _cpfController.text),
                _linhaDado('RG', _rgController.text),
                _linhaDado('CNH', _cnhController.text),
                _linhaDado('Endereço', _enderecoController.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Documentos Cadastrados:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _previewDoc('CNH', _fotoCnh)),
            const SizedBox(width: 10),
            Expanded(child: _previewDoc('Comprovante', _fotoComprovante)),
          ],
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _gerarPdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('GERAR DRIVER ID'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _linhaDado(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(valor, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildFotoPicker(String label, File? arquivo, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            image: arquivo != null ? DecorationImage(image: FileImage(arquivo), fit: BoxFit.cover) : null,
          ),
          child: arquivo == null ? const Icon(Icons.camera_alt) : null,
        ),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _previewDoc(String label, File? arquivo) {
    return Column(
      children: [
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            image: arquivo != null ? DecorationImage(image: FileImage(arquivo), fit: BoxFit.cover) : null,
          ),
          child: arquivo == null ? const Center(child: Text('Pendente', style: TextStyle(color: Colors.red))) : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}