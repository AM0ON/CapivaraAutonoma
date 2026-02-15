import 'dart:typed_data';

enum StatusFrete {
  rascunho,
  aguardandoPagamento,
  pago,
  motoristaSelecionado,
  aguardandoComprovanteCarregamento,
  carregamentoValidado,
  emTransito,
  aguardandoComprovanteEntrega,
  entregaValidada,
  finalizado,
  cancelado,
  emDisputa,
  estornoEmAndamento
}

class Frete {
  final Uint8List id; 
  final String empresa;
  final String responsavel;
  final String documento;
  final String telefone;
  final String origem;
  final String destino;
  final double valorBase;
  final double taxaMediacao;
  final double taxasPsp;
  final StatusFrete status;
  final String? chavePixMotorista;
  final String? dataColeta;
  final String? dataEntrega;

  Frete({
    required this.id,
    required this.empresa,
    required this.responsavel,
    required this.documento,
    required this.telefone,
    required this.origem,
    required this.destino,
    required this.valorBase,
    this.taxaMediacao = 0.0,
    this.taxasPsp = 0.0,
    this.status = StatusFrete.rascunho,
    this.chavePixMotorista,
    this.dataColeta,
    this.dataEntrega,
  });

  double get valorTotalEmbarcador => valorBase + taxaMediacao + taxasPsp;

  Map<String, dynamic> paraMapa() {
    return {
      'id': id,
      'empresa': empresa,
      'responsavel': responsavel,
      'documento': documento,
      'telefone': telefone,
      'origem': origem,
      'destino': destino,
      'valorBase': valorBase,
      'taxaMediacao': taxaMediacao,
      'taxasPsp': taxasPsp,
      'status': status.index,
      'chavePixMotorista': chavePixMotorista,
      'dataColeta': dataColeta,
      'dataEntrega': dataEntrega,
    };
  }

  factory Frete.doMapa(Map<String, dynamic> mapa) {
    return Frete(
      id: mapa['id'] as Uint8List,
      empresa: mapa['empresa'],
      responsavel: mapa['responsavel'],
      documento: mapa['documento'],
      telefone: mapa['telefone'],
      origem: mapa['origem'],
      destino: mapa['destino'],
      valorBase: (mapa['valorBase'] as num).toDouble(),
      taxaMediacao: (mapa['taxaMediacao'] as num).toDouble(),
      taxasPsp: (mapa['taxasPsp'] as num).toDouble(),
      status: StatusFrete.values[mapa['status'] as int],
      chavePixMotorista: mapa['chavePixMotorista'],
      dataColeta: mapa['dataColeta'],
      dataEntrega: mapa['dataEntrega'],
    );
  }
}