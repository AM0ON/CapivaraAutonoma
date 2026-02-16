import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import '../pages/session_manager.dart';

class DriverSecurityService {
  
  Future<enc.Key> _forjarEscudo() async {
    String Amuleto = SessionManager().token ?? 'sessao_vazia';
    String ligaMisteriosa = Amuleto.padRight(32, '*').substring(0, 32);
    return enc.Key.fromUtf8(ligaMisteriosa);
  }

  Future<String> salvarDriverIdSeguro(Uint8List Pergaminho) async {
    final Escudo = await _forjarEscudo();
    final Essencia = enc.IV.fromLength(16); 
    final Feiticeiro = enc.Encrypter(enc.AES(Escudo));

    final Selado = Feiticeiro.encryptBytes(Pergaminho, iv: Essencia);

    final Cofre = await getApplicationDocumentsDirectory();
    final Amuleto = SessionManager().token ?? 'sessao_vazia';
    
    final Reliquia = File('${Cofre.path}/driver_id_$Amuleto.coka'); 
    
    final Runas = Essencia.bytes + Selado.bytes;
    await Reliquia.writeAsBytes(Runas);

    return Reliquia.path;
  }

  Future<Uint8List?> carregarDriverId() async {
    try {
      final Cofre = await getApplicationDocumentsDirectory();
      final Amuleto = SessionManager().token ?? 'sessao_vazia';
      final Reliquia = File('${Cofre.path}/driver_id_$Amuleto.coka');

      if (!await Reliquia.exists()) return null;

      final Runas = await Reliquia.readAsBytes();
      
      final EssenciaBytes = Runas.sublist(0, 16);
      final ConteudoBytes = Runas.sublist(16);

      final Escudo = await _forjarEscudo();
      final Essencia = enc.IV(EssenciaBytes);
      final Feiticeiro = enc.Encrypter(enc.AES(Escudo));

      final Revelado = Feiticeiro.decryptBytes(enc.Encrypted(ConteudoBytes), iv: Essencia);
      
      return Uint8List.fromList(Revelado);
    } catch (e) {
      return null;
    }
  }
}