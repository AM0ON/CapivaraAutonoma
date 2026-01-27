import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MinhaContaPage extends StatefulWidget {
  // Removemos os parâmetros do construtor, pois vamos carregar do disco
  const MinhaContaPage({super.key});

  @override
  State<MinhaContaPage> createState() => _MinhaContaPageState();
}

class _MinhaContaPageState extends State<MinhaContaPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  File? _fotoPerfil;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nomeController.text = prefs.getString('perfil_nome') ?? '';
      _emailController.text = prefs.getString('perfil_email') ?? '';
      
      final pathFoto = prefs.getString('perfil_foto');
      if (pathFoto != null && pathFoto.isNotEmpty) {
        _fotoPerfil = File(pathFoto);
      }
      _carregando = false;
    });
  }

  Future<void> _salvarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('perfil_nome', _nomeController.text.trim());
    await prefs.setString('perfil_email', _emailController.text.trim());
    
    if (_fotoPerfil != null) {
      await prefs.setString('perfil_foto', _fotoPerfil!.path);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado!')),
      );
      // Retorna true para avisar quem chamou que houve mudança
      Navigator.pop(context, true); 
    }
  }

  Future<void> _alterarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    
    if (picked != null) {
      setState(() {
        _fotoPerfil = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final corPrimaria = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Conta'),
      ),
      body: _carregando 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _fotoPerfil != null ? FileImage(_fotoPerfil!) : null,
                    child: _fotoPerfil == null 
                      ? Icon(Icons.person, size: 60, color: Colors.grey.shade400) 
                      : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: corPrimaria,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        onPressed: _alterarFoto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome de Exibição',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _salvarPerfil,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('SALVAR ALTERAÇÕES'),
            ),
          ],
        ),
    );
  }
}