import 'package:flutter/services.dart';

class CidadeService {
  static bool _iniciado = false;
  static Future<void>? _carregando;

  static final List<String> _cidades = [];
  static final List<String> _cidadesNormalizadas = [];

  static Future<void> init() {
    if (_iniciado) return Future.value();
    _carregando ??= _carregar();
    return _carregando!;
  }

  static Future<void> _carregar() async {
    final conteudo = await rootBundle.loadString('lib/utils/assets/cidades.txt');

    final linhas = conteudo
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    _cidades
      ..clear()
      ..addAll(linhas);

    _cidadesNormalizadas
      ..clear()
      ..addAll(linhas.map(_normalizar));

    _iniciado = true;
  }

  static List<String> search(String pattern) {
    if (!_iniciado) return [];

    final termo = _normalizar(pattern);

    if (termo.isEmpty) return [];
    if (termo.length < 2) return [];

    const limite = 20;
    final resultados = <String>[];

    for (var i = 0; i < _cidadesNormalizadas.length; i++) {
      if (_cidadesNormalizadas[i].contains(termo)) {
        resultados.add(_cidades[i]);
        if (resultados.length >= limite) break;
      }
    }

    return resultados;
  }

  static String _normalizar(String texto) {
    var t = texto.trim().toLowerCase();
    if (t.isEmpty) return 'Não encontrado';

    t = t
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c');

    return t;
  }
}
