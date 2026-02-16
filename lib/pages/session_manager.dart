class SessionManager {
  static final SessionManager _instancia = SessionManager._interno();
  factory SessionManager() => _instancia;
  SessionManager._interno();

  bool _estaLogado = false;
  bool _kycAprovado = false;
  String? _tokenVolatil;

  bool get estaLogado => _estaLogado;
  bool get kycAprovado => _kycAprovado;
  String? get token => _tokenVolatil;

  Future<bool> simularLoginGoogle() async {
    await Future.delayed(const Duration(seconds: 2));
    _estaLogado = true;
    _tokenVolatil = "jwt_simulado_em_ram_${DateTime.now().millisecondsSinceEpoch}";
    _kycAprovado = false; 
    return true;
  }

  Future<bool> simularEnvioKyc() async {
    await Future.delayed(const Duration(seconds: 3));
    _kycAprovado = true;
    return true;
  }

  void encerrarSessao() {
    _estaLogado = false;
    _kycAprovado = false;
    _tokenVolatil = null;
  }
}