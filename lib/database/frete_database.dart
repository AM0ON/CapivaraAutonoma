import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:typed_data';
import '../models/frete.dart';

class Despesa {
  final int? id;
  final Uint8List freteId;
  final String tipo;
  final double valor;
  final String? observacao;
  final String criadoEm;

  Despesa({this.id, required this.freteId, required this.tipo, required this.valor, this.observacao, required this.criadoEm});

  Map<String, dynamic> paraMapa() => {
    'id': id,
    'freteId': freteId,
    'tipo': tipo,
    'valor': valor,
    'observacao': observacao,
    'criadoEm': criadoEm,
  };

  factory Despesa.doMapa(Map<String, dynamic> mapa) => Despesa(
    id: mapa['id'],
    freteId: mapa['freteId'] as Uint8List,
    tipo: mapa['tipo'],
    valor: (mapa['valor'] as num).toDouble(),
    observacao: mapa['observacao'],
    criadoEm: mapa['criadoEm'],
  );
}

class FreteDatabase {
  static final FreteDatabase instance = FreteDatabase._init();
  static Database? _database;

  FreteDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('meu_frete_v7.db');
    return _database!;
  }

  Future<Database> _initDB(String caminho) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, caminho);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE fretes (
        id BLOB PRIMARY KEY,
        empresa TEXT NOT NULL,
        responsavel TEXT NOT NULL,
        documento TEXT NOT NULL,
        telefone TEXT NOT NULL,
        origem TEXT NOT NULL,
        destino TEXT NOT NULL,
        valorBase REAL NOT NULL,
        taxaMediacao REAL NOT NULL,
        taxasPsp REAL NOT NULL,
        status INTEGER NOT NULL,
        chavePixMotorista TEXT,
        dataColeta TEXT,
        dataEntrega TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE despesas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        freteId BLOB NOT NULL,
        tipo TEXT NOT NULL,
        valor REAL NOT NULL,
        observacao TEXT,
        criadoEm TEXT NOT NULL,
        FOREIGN KEY (freteId) REFERENCES fretes(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- MÉTODOS DE FRETE ---

  Future<void> inserirFrete(Frete frete) async {
    final db = await database;
    await db.insert('fretes', frete.paraMapa());
  }

  Future<List<Frete>> listarFretes() async {
    final db = await database;
    final resultado = await db.query('fretes', orderBy: 'dataColeta DESC');
    return resultado.map((json) => Frete.doMapa(json)).toList();
  }

  Future<void> atualizarFrete(Frete frete) async {
    final db = await database;
    await db.update(
      'fretes',
      frete.paraMapa(),
      where: 'id = ?',
      whereArgs: [frete.id],
    );
  }

  Future<void> deletarFrete(Uint8List id) async {
    final db = await database;
    await db.delete('fretes', where: 'id = ?', whereArgs: [id]);
  }

  // --- MÉTODOS DE DESPESAS ---

  Future<void> inserirDespesa(Despesa despesa) async {
    final db = await database;
    await db.insert('despesas', despesa.paraMapa());
  }

  Future<List<Despesa>> listarDespesasPorFreteId(Uint8List freteId) async {
    final db = await database;
    final resultado = await db.query(
      'despesas',
      where: 'freteId = ?',
      whereArgs: [freteId],
    );
    return resultado.map((json) => Despesa.doMapa(json)).toList();
  }

  Future<void> deletarDespesa(int id) async {
    final db = await database;
    await db.delete('despesas', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> calcularTotalDespesas(Uint8List freteId) async {
    final db = await database;
    final resultado = await db.rawQuery(
      'SELECT SUM(valor) as total FROM despesas WHERE freteId = ?',
      [freteId],
    );
    return (resultado.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}