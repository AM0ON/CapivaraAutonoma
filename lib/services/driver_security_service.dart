import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import '../pages/session_manager.dart'; // Para pegar o UUID

class DriverSecurityService {
  
  // Gera uma chave de criptografia baseada no UUID do motorista
  // Isso garante que o arquivo é VINCULADO ao usuário.
  Future<enc.Key> _gerarChaveUsuario() async {
    String uuid = await SessionManager.getUserId();
    
    // O AES precisa de uma chave de 32 caracteres exatos.
    // Vamos pegar o UUID e preencher ou cortar para dar 32 chars.
    String keyString = uuid.padRight(32, '*').substring(0, 32);
    return enc.Key.fromUtf8(keyString);
  }

  // 1. CRIPTOGRAFA E SALVA
  Future<String> salvarDriverIdSeguro(Uint8List pdfBytes) async {
    final key = await _gerarChaveUsuario();
    final iv = enc.IV.fromLength(16); // Vetor de Inicialização (padrão de segurança)
    final encrypter = enc.Encrypter(enc.AES(key));

    // Criptografa os bytes do PDF
    final encrypted = encrypter.encryptBytes(pdfBytes, iv: iv);

    // Define o caminho do arquivo
    final directory = await getApplicationDocumentsDirectory();
    final uuid = await SessionManager.getUserId();
    // Extensão .coka (Capivara Loka) para ninguém saber que é PDF kkk
    final file = File('${directory.path}/driver_id_$uuid.coka'); 
    
    // Salva o IV (16 bytes) + Conteúdo Criptografado
    // Precisamos do IV para descriptografar depois, então salvamos junto no começo do arquivo
    final bytesParaSalvar = iv.bytes + encrypted.bytes;
    await file.writeAsBytes(bytesParaSalvar);

    return file.path;
  }

  // 2. CARREGA E DESCRIPTOGRAFA (Para visualizar ou compartilhar)
  Future<Uint8List?> carregarDriverId() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final uuid = await SessionManager.getUserId();
      final file = File('${directory.path}/driver_id_$uuid.coka');

      if (!await file.exists()) return null;

      // Lê tudo
      final allBytes = await file.readAsBytes();
      
      // Separa o IV (primeiros 16 bytes) do Conteúdo
      final ivBytes = allBytes.sublist(0, 16);
      final contentBytes = allBytes.sublist(16);

      // Prepara a chave
      final key = await _gerarChaveUsuario();
      final iv = enc.IV(ivBytes);
      final encrypter = enc.Encrypter(enc.AES(key));

      // Descriptografa
      final decrypted = encrypter.decryptBytes(enc.Encrypted(contentBytes), iv: iv);
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      print('Erro ao descriptografar: $e');
      return null;
    }
  }
}