import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/frete.dart';
import '../models/motorista.dart';

class FreteDatabase {
  static final FreteDatabase instance = FreteDatabase._init();
  static Database? _database;

  FreteDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fretes_v2.db');

    _database = await openDatabase(
      path,
      version: 6, // Versão 6: Adição de Endereço
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

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

    await db.execute('''
      CREATE TABLE motorista (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        rg TEXT,
        cpf TEXT,
        cnh TEXT,
        endereco TEXT,
        foto_rosto TEXT,
        foto_cnh TEXT,
        foto_comprovante TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS motorista (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT,
          rg TEXT,
          cpf TEXT,
          cnh TEXT,
          foto_rosto TEXT,
          foto_cnh TEXT,
          foto_comprovante TEXT
        )
      ''');
    }
    
    // Atualização para versão 6: Adiciona coluna endereço se não existir
    if (oldVersion < 6) {
      // Verifica se a tabela existe antes de alterar
      try {
         await db.execute('ALTER TABLE motorista ADD COLUMN endereco TEXT');
      } catch (e) {
         // Se a tabela não existia, o create table acima já resolveu ou criamos agora
         await db.execute('''
          CREATE TABLE IF NOT EXISTS motorista (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT,
            rg TEXT,
            cpf TEXT,
            cnh TEXT,
            endereco TEXT,
            foto_rosto TEXT,
            foto_cnh TEXT,
            foto_comprovante TEXT
          )
        ''');
      }
    }
  }

  // --- MÉTODOS DE FRETE ---
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

  // --- MÉTODOS DE DESPESAS ---
  Future<int> inserirDespesa(Despesa despesa) async {
    final db = await database;
    return await db.insert('despesas', despesa.toMap());
  }

  Future<List<Despesa>> getDespesas(int freteId) async {
    final db = await database;
    final result = await db.query(
      'despesas',
      where: 'freteId = ?',
      whereArgs: [freteId],
      orderBy: 'criadoEm DESC',
    );
    return result.map((e) => Despesa.fromMap(e)).toList();
  }

  Future<int> deleteDespesa(int id) async {
    final db = await database;
    return await db.delete(
      'despesas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> totalDespesasDoFrete(int freteId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(valor) as total FROM despesas WHERE freteId = ?',
      [freteId],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return double.tryParse(result.first['total'].toString()) ?? 0.0;
    }
    return 0.0;
  }

  Future<Map<int, double>> getTotaisDespesasPorFrete(List<int> freteIds) async {
    final db = await database;
    if (freteIds.isEmpty) return {};

    final idsString = freteIds.join(',');
    final result = await db.rawQuery('''
      SELECT freteId, SUM(valor) as total
      FROM despesas
      WHERE freteId IN ($idsString)
      GROUP BY freteId
    ''');

    final map = <int, double>{};
    for (final row in result) {
      final fid = row['freteId'] as int;
      final total = row['total'] != null 
          ? (double.tryParse(row['total'].toString()) ?? 0.0) 
          : 0.0;
      map[fid] = total;
    }
    return map;
  }

  // --- MÉTODOS DE MOTORISTA ---
  Future<Motorista?> getMotorista() async {
    final db = await database;
    try {
      final result = await db.query('motorista', limit: 1);
      if (result.isNotEmpty) {
        return Motorista.fromMap(result.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> salvarMotorista(Motorista motorista) async {
    final db = await database;
    final existe = await getMotorista();
    
    if (existe == null) {
      await db.insert('motorista', motorista.toMap());
    } else {
      await db.update('motorista', motorista.toMap(), where: 'id = ?', whereArgs: [existe.id]);
    }
  }
}