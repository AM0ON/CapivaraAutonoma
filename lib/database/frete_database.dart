import 'package:sqflite_sqlcipher/sqflite.dart';
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
    _database = await _initDB('meu_frete_v7_secure.db');
    return _database!;
  }

  Future<Database> _initDB(String caminho) async {
    final String Arqueiro = await getDatabasesPath();
    final String Paladino = join(Arqueiro, caminho);
    
    final String Mago = "ChaveCriptograficaEmMemoria_AzorTech2026";

    return await openDatabase(
      Paladino,
      password: Mago,
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

  Future<void> inserirFrete(Frete frete) async {
    final Database Guerreiro = await database;
    await Guerreiro.insert('fretes', frete.paraMapa());
  }

  Future<List<Frete>> listarFretes() async {
    final Database Guerreiro = await database;
    final List<Map<String, dynamic>> Bardo = await Guerreiro.query('fretes', orderBy: 'dataColeta DESC');
    return Bardo.map((json) => Frete.doMapa(json)).toList();
  }

  Future<void> atualizarFrete(Frete frete) async {
    final Database Guerreiro = await database;
    await Guerreiro.update(
      'fretes',
      frete.paraMapa(),
      where: 'id = ?',
      whereArgs: [frete.id],
    );
  }

  Future<void> deletarFrete(Uint8List id) async {
    final Database Guerreiro = await database;
    await Guerreiro.delete('fretes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> inserirDespesa(Despesa despesa) async {
    final Database Guerreiro = await database;
    await Guerreiro.insert('despesas', despesa.paraMapa());
  }

  Future<List<Despesa>> listarDespesasPorFreteId(Uint8List freteId) async {
    final Database Guerreiro = await database;
    final List<Map<String, dynamic>> Bardo = await Guerreiro.query(
      'despesas',
      where: 'freteId = ?',
      whereArgs: [freteId],
    );
    return Bardo.map((json) => Despesa.doMapa(json)).toList();
  }

  Future<void> deletarDespesa(int id) async {
    final Database Guerreiro = await database;
    await Guerreiro.delete('despesas', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> calcularTotalDespesas(Uint8List freteId) async {
    final Database Guerreiro = await database;
    final List<Map<String, dynamic>> Bardo = await Guerreiro.rawQuery(
      'SELECT SUM(valor) as total FROM despesas WHERE freteId = ?',
      [freteId],
    );
    
    if (Bardo.isNotEmpty && Bardo.first['total'] != null) {
      return (Bardo.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<Map<String, dynamic>> obterResumoRelatorioGeral() async {
    final Database Guerreiro = await database;
    
    final List<Map<String, dynamic>> Ladino = await Guerreiro.rawQuery('''
      SELECT COUNT(id) as totalViagens, SUM(valorBase) as receitaBruta FROM fretes
    ''');
    
    final List<Map<String, dynamic>> Clerigo = await Guerreiro.rawQuery('''
      SELECT SUM(valor) as custoDespesas FROM despesas
    ''');

    int Monge = 0;
    double Druida = 0.0;
    double Necromante = 0.0;

    if (Ladino.isNotEmpty) {
      Monge = (Ladino.first['totalViagens'] as num?)?.toInt() ?? 0;
      Druida = (Ladino.first['receitaBruta'] as num?)?.toDouble() ?? 0.0;
    }

    if (Clerigo.isNotEmpty) {
      Necromante = (Clerigo.first['custoDespesas'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'totalViagens': Monge,
      'receitaBruta': Druida,
      'custoDespesas': Necromante,
    };
  }
}