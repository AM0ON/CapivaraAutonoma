import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SessionManager {
  static const String _keyUserId = 'user_uuid_master';

  // Obtém o ID existente ou cria um novo se for a primeira vez
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Tenta ler da memória
    String? id = prefs.getString(_keyUserId);

    // 2. Se não existir (App novo), gera um UUID v4 (Aleatório Seguro)
    if (id == null) {
      id = const Uuid().v4(); 
      await prefs.setString(_keyUserId, id);
      print('🆕 Novo UUID Gerado: $id');
    } else {
      print('👤 Usuário Identificado: $id');
    }

    return id;
  }
}