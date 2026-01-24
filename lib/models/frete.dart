class Frete {
  final int? id;
  final String empresa;
  final String responsavel;
  final String documento;
  final String telefone;
  final String origem;
  final String destino;
  final double valorFrete;
  final double valorPago;
  final double valorFaltante;
  final String statusPagamento;

  final String statusFrete;
  final String? dataColeta;
  final String? dataEntrega;
  final String? motivoRejeicao;

  Frete({
    this.id,
    required this.empresa,
    required this.responsavel,
    required this.documento,
    required this.telefone,
    required this.origem,
    required this.destino,
    required this.valorFrete,
    required this.valorPago,
    required this.valorFaltante,
    required this.statusPagamento,
    this.statusFrete = 'Pendente',
    this.dataColeta,
    this.dataEntrega,
    this.motivoRejeicao,
  });

  Frete copyWith({
    int? id,
    String? empresa,
    String? responsavel,
    String? documento,
    String? telefone,
    String? origem,
    String? destino,
    double? valorFrete,
    double? valorPago,
    double? valorFaltante,
    String? statusPagamento,
    String? statusFrete,
    String? dataColeta,
    String? dataEntrega,
    String? motivoRejeicao,
  }) {
    return Frete(
      id: id ?? this.id,
      empresa: empresa ?? this.empresa,
      responsavel: responsavel ?? this.responsavel,
      documento: documento ?? this.documento,
      telefone: telefone ?? this.telefone,
      origem: origem ?? this.origem,
      destino: destino ?? this.destino,
      valorFrete: valorFrete ?? this.valorFrete,
      valorPago: valorPago ?? this.valorPago,
      valorFaltante: valorFaltante ?? this.valorFaltante,
      statusPagamento: statusPagamento ?? this.statusPagamento,
      statusFrete: statusFrete ?? this.statusFrete,
      dataColeta: dataColeta ?? this.dataColeta,
      dataEntrega: dataEntrega ?? this.dataEntrega,
      motivoRejeicao: motivoRejeicao ?? this.motivoRejeicao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresa': empresa,
      'responsavel': responsavel,
      'documento': documento,
      'telefone': telefone,
      'origem': origem,
      'destino': destino,
      'valorFrete': valorFrete,
      'valorPago': valorPago,
      'valorFaltante': valorFaltante,
      'statusPagamento': statusPagamento,
      'statusFrete': statusFrete,
      'dataColeta': dataColeta,
      'dataEntrega': dataEntrega,
      'motivoRejeicao': motivoRejeicao,
    };
  }

  factory Frete.fromMap(Map<String, dynamic> map) {
    double d(v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;

    return Frete(
      id: map['id'] as int?,
      empresa: map['empresa'],
      responsavel: map['responsavel'],
      documento: map['documento'],
      telefone: map['telefone'],
      origem: map['origem'],
      destino: map['destino'],
      valorFrete: d(map['valorFrete']),
      valorPago: d(map['valorPago']),
      valorFaltante: d(map['valorFaltante']),
      statusPagamento: map['statusPagamento'],
      statusFrete: (map['statusFrete'] ?? 'Pendente').toString(),
      dataColeta: map['dataColeta']?.toString(),
      dataEntrega: map['dataEntrega']?.toString(),
      motivoRejeicao: map['motivoRejeicao']?.toString(),
    );
  }
}
