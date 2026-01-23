import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/frete.dart';

class FreteDatabase {
  static final FreteDatabase instance = FreteDatabase._init();
  static Database? _database;

  FreteDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fretes.db');

    _database = await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    await _database!.execute('PRAGMA foreign_keys = ON');

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE fretes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        empresa TEXT NOT NULL,
        responsavel TEXT NOT NULL,
        documento TEXT NOT NULL,
        telefone TEXT NOT NULL,
        origem TEXT NOT NULL,
        destino TEXT NOT NULL,
        valorFrete REAL NOT NULL,
        valorPago REAL NOT NULL,
        valorFaltante REAL NOT NULL,
        statusPagamento TEXT NOT NULL,
        statusFrete TEXT NOT NULL,
        dataColeta TEXT,
        dataEntrega TEXT,
        motivoRejeicao TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE despesas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        freteId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        valor REAL NOT NULL,
        observacao TEXT,
        criadoEm TEXT NOT NULL,
        FOREIGN KEY (freteId) REFERENCES fretes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_despesas_freteId ON despesas(freteId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS despesas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          freteId INTEGER NOT NULL,
          tipo TEXT NOT NULL,
          valor REAL NOT NULL,
          observacao TEXT,
          criadoEm TEXT NOT NULL,
          FOREIGN KEY (freteId) REFERENCES fretes(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_despesas_freteId ON despesas(freteId)',
      );
    }
  }

  Future<int> inserirFrete(Frete frete) async {
    final db = await database;
    return await db.insert('fretes', frete.toMap());
  }

  Future<List<Frete>> getFretes() async {
    final db = await database;
    final result = await db.query('fretes', orderBy: 'id DESC');
    return result.map((e) => Frete.fromMap(e)).toList();
  }

  Future<int> updateFrete(Frete frete) async {
    final db = await database;
    return await db.update(
      'fretes',
      frete.toMap(),
      where: 'id = ?',
      whereArgs: [frete.id],
    );
  }

  Future<int> deleteFrete(int id) async {
    final db = await database;
    return await db.delete(
      'fretes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> limparBanco() async {
    final db = await database;
    await db.delete('despesas');
    await db.delete('fretes');
  }

  Future<int> inserirDespesa({
    required int freteId,
    required String tipo,
    required double valor,
    required String observacao,
    required String criadoEm,
  }) async {
    final db = await database;
    return await db.insert('despesas', {
      'freteId': freteId,
      'tipo': tipo,
      'valor': valor,
      'observacao': observacao,
      'criadoEm': criadoEm,
    });
  }

  Future<int> removerDespesa(int id) async {
    final db = await database;
    return await db.delete('despesas', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> listarDespesasDoFrete(int freteId) async {
    final db = await database;
    return await db.query(
      'despesas',
      where: 'freteId = ?',
      whereArgs: [freteId],
      orderBy: 'id DESC',
    );
  }

  Future<double> totalDespesasDoFrete(int freteId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(valor), 0) as total FROM despesas WHERE freteId = ?',
      [freteId],
    );

    final total = result.first['total'];
    if (total is num) return total.toDouble();
    return double.tryParse('$total') ?? 0.0;
  }

  Future<Map<int, double>> getTotaisDespesasPorFrete(List<int> freteIds) async {
    final db = await database;
    if (freteIds.isEmpty) return {};

    final placeholders = List.filled(freteIds.length, '?').join(',');

    final result = await db.rawQuery(
      '''
      SELECT freteId, COALESCE(SUM(valor), 0) as total
      FROM despesas
      WHERE freteId IN ($placeholders)
      GROUP BY freteId
      ''',
      freteIds,
    );

    final Map<int, double> mapa = {};

    for (final row in result) {
      final id = row['freteId'];
      final total = row['total'];

      final freteId = id is int ? id : int.tryParse('$id') ?? 0;
      final valorTotal =
          total is num ? total.toDouble() : (double.tryParse('$total') ?? 0.0);

      mapa[freteId] = valorTotal;
    }

    return mapa;
  }
}
