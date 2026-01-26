class Motorista {
  final int? id;
  final String? nome;
  final String? rg;
  final String? cpf;
  final String? cnh;
  final String? fotoRosto;
  final String? fotoCnh;
  final String? fotoComprovante;

  Motorista({
    this.id,
    this.nome,
    this.rg,
    this.cpf,
    this.cnh,
    this.fotoRosto,
    this.fotoCnh,
    this.fotoComprovante,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'rg': rg,
      'cpf': cpf,
      'cnh': cnh,
      'foto_rosto': fotoRosto,
      'foto_cnh': fotoCnh,
      'foto_comprovante': fotoComprovante,
    };
  }

  factory Motorista.fromMap(Map<String, dynamic> map) {
    return Motorista(
      id: map['id'],
      nome: map['nome'],
      rg: map['rg'],
      cpf: map['cpf'],
      cnh: map['cnh'],
      fotoRosto: map['foto_rosto'],
      fotoCnh: map['foto_cnh'],
      fotoComprovante: map['foto_comprovante'],
    );
  }
}