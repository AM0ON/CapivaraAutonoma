import 'package:flutter/services.dart';

class CidadeService {
  static List<String> _cache = [];
  static bool _loaded = false;

  // ⚠️ TEM que ser exatamente o mesmo caminho do pubspec.yaml
  static const String assetPath = 'lib/utils/assets/cidades.txt';

  static Future<void> init() async {
    if (_loaded) return;

    final raw = await rootBundle.loadString(assetPath);
    _cache = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    _loaded = true;

    // ✅ DEBUG: veja no console se carregou 5000+ cidades
    // ignore: avoid_print
    print('CidadeService: carregou ${_cache.length} cidades de $assetPath');
  }

  static Future<List<String>> search(String query) async {
    await init();

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final res = _cache
        .where((c) => c.toLowerCase().contains(q))
        .take(12)
        .toList();

    // ✅ DEBUG: veja se está retornando sugestões
    // ignore: avoid_print
    print('CidadeService.search("$query") => ${res.length} resultados');

    return res;
  }

  // ✅ teste rápido: pega 5 cidades
  static Future<List<String>> first5() async {
    await init();
    return _cache.take(5).toList();
  }
}
