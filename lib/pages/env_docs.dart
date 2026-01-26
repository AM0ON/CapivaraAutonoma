import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/frete_database.dart';
import '../models/frete.dart';

class DocumentosPage extends StatefulWidget {
  const DocumentosPage({super.key});

  @override
  State<DocumentosPage> createState() => _DocumentosPageState();
}

class _DocumentosPageState extends State<DocumentosPage> {
  final FreteDatabase _db = FreteDatabase.instance;
  final ImagePicker _picker = ImagePicker();

  List<Frete> _fretes = [];
  Frete? _freteSelecionado;
  String _tipoDocumento = 'Canhoto Assinado';
  File? _imagemSelecionada;
  bool _enviando = false;

  final List<String> _tiposDoc = [
    'Canhoto Assinado',
    'Nota Fiscal',
    'Comprovante de Despesa',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _carregarFretes();
  }

  Future<void> _carregarFretes() async {
    final lista = await _db.getFretes();
    // Você pode filtrar aqui para mostrar apenas fretes pendentes/entregues se quiser
    setState(() {
      _fretes = lista;
    });
  }

  Future<void> _selecionarImagem(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo != null) {
        setState(() {
          _imagemSelecionada = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  Future<void> _enviarDocumento() async {
    if (_freteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um frete!')),
      );
      return;
    }
    if (_imagemSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tire uma foto ou escolha da galeria!')),
      );
      return;
    }

    setState(() => _enviando = true);

    // Simulação de envio
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _enviando = false;
      _imagemSelecionada = null;
      _freteSelecionado = null;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sucesso!'),
        content: const Text('Documento vinculado com sucesso.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final corPrimaria = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Envio de Documentos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cardSelecao(),
            const SizedBox(height: 16),
            _areaFoto(corPrimaria),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _enviando ? null : _enviarDocumento,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: corPrimaria,
                foregroundColor: Colors.white,
              ),
              icon: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_enviando ? 'Enviando...' : 'Enviar Documento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardSelecao() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vincular ao Frete',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Frete>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Selecione o Frete',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping_outlined),
              ),
              value: _freteSelecionado,
              items: _fretes.map((f) {
                return DropdownMenuItem(
                  value: f,
                  child: Text(
                    '${f.id} - ${f.destino} (${f.empresa})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _freteSelecionado = val),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tipo de Documento',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              value: _tipoDocumento,
              items: _tiposDoc.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _tipoDocumento = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _areaFoto(Color cor) {
    return Column(
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: _imagemSelecionada != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _imagemSelecionada!,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_search, size: 60, color: cor.withOpacity(0.5)),
                    const SizedBox(height: 10),
                    Text(
                      'Nenhuma imagem selecionada',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selecionarImagem(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Câmera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selecionarImagem(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeria'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}