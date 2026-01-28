import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_manager.dart'; // <--- IMPORTANTE: Importe o arquivo que criamos

// ==========================================
// 1. MODELO DE DADOS (Com User ID) 📦
// ==========================================
class PontoParada {
  String id;      // ID do Ponto (do documento)
  String userId;  // <--- NOVO: ID do Motorista (Dono do ponto)
  String nome;
  String endereco;
  String tipo; 
  LatLng localizacao;
  double nota;

  PontoParada({
    required this.id,
    required this.userId, // Obrigatório
    required this.nome,
    required this.tipo,
    required this.localizacao,
    this.endereco = '',
    this.nota = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId, // Salva quem criou
      'nome': nome,
      'tipo': tipo,
      'lat': localizacao.latitude,
      'lng': localizacao.longitude,
      'endereco': endereco,
      'nota': nota,
    };
  }

  factory PontoParada.fromMap(Map<String, dynamic> map) {
    return PontoParada(
      id: map['id'] ?? '',
      userId: map['userId'] ?? 'anonimo', // Fallback se for antigo
      nome: map['nome'] ?? '',
      tipo: map['tipo'] ?? 'Outro',
      localizacao: LatLng(map['lat'] ?? 0.0, map['lng'] ?? 0.0),
      endereco: map['endereco'] ?? '',
      nota: map['nota'] ?? 0.0,
    );
  }
}

// ==========================================
// 2. REPOSITÓRIO
// ==========================================
class MapRepository {
  static const String _key = 'meus_pontos_mapa';

  Future<void> salvarPonto(PontoParada ponto) async {
    List<PontoParada> listaAtual = await listarPontos();
    listaAtual.add(ponto);
    await _salvarNoDisco(listaAtual);
    
    // FUTURO FIREBASE:
    // O userId já está dentro do objeto ponto.
    // await FirebaseFirestore.instance
    //     .collection('pontos')
    //     .doc(ponto.id)
    //     .set(ponto.toMap());
  }

  Future<void> removerPonto(String id) async {
    List<PontoParada> listaAtual = await listarPontos();
    listaAtual.removeWhere((p) => p.id == id);
    await _salvarNoDisco(listaAtual);
  }

  Future<List<PontoParada>> listarPontos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dadosJson = prefs.getString(_key);
    if (dadosJson == null) return [];

    final List<dynamic> listaDecodificada = jsonDecode(dadosJson);
    return listaDecodificada.map((item) => PontoParada.fromMap(item)).toList();
  }

  Future<void> _salvarNoDisco(List<PontoParada> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final String dadosJson = jsonEncode(lista.map((p) => p.toMap()).toList());
    await prefs.setString(_key, dadosJson);
  }
}

// ==========================================
// 3. TELA (UI)
// ==========================================
class MapasPage extends StatefulWidget {
  const MapasPage({super.key});

  @override
  State<MapasPage> createState() => _MapasPageState();
}

class _MapasPageState extends State<MapasPage> {
  final MapController _mapController = MapController();
  final MapRepository _repository = MapRepository();
  
  LatLng? _minhaLocalizacao;
  StreamSubscription<Position>? _posicaoStream;
  bool _primeiraLocalizacaoRecebida = false;
  bool _mapaPronto = false;
  bool _modoAdicao = false;

  List<PontoParada> _pontos = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _iniciarRastreamentoGPS();
  }

  @override
  void dispose() {
    _posicaoStream?.cancel();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final lista = await _repository.listarPontos();
    setState(() {
      _pontos = lista;
    });
  }

  // --- GPS ---
  Future<void> _iniciarRastreamentoGPS() async {
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) return;

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) return;
    }
    
    const settings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
    _posicaoStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position posicao) {
      setState(() {
        _minhaLocalizacao = LatLng(posicao.latitude, posicao.longitude);
      });
      if (!_primeiraLocalizacaoRecebida && _mapaPronto) {
        _moverCameraParaUsuario();
        _primeiraLocalizacaoRecebida = true;
      }
    });
  }

  void _moverCameraParaUsuario() {
    if (_minhaLocalizacao != null) {
      try {
        _mapController.move(_minhaLocalizacao!, 15.0);
      } catch (e) {
        debugPrint('Erro mapController: $e');
      }
    }
  }

  // --- ADICIONAR PONTO (Agora com UUID) ---
  void _confirmarAdicao() {
    final LatLng centro = _mapController.camera.center;
    final nomeCtrl = TextEditingController();
    String tipoSelecionado = 'Posto';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Novo Local'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nomeCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder())),
                  const SizedBox(height: 15),
                  DropdownButton<String>(
                    value: tipoSelecionado,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Posto', child: Row(children: [Icon(Icons.local_gas_station, color: Colors.blue), SizedBox(width: 8), Text('Posto')])),
                      DropdownMenuItem(value: 'Fiscalizacao', child: Row(children: [Icon(Icons.local_police, color: Colors.red), SizedBox(width: 8), Text('Fiscalização')])),
                      DropdownMenuItem(value: 'Oficina', child: Row(children: [Icon(Icons.build, color: Colors.orange), SizedBox(width: 8), Text('Oficina')])),
                      DropdownMenuItem(value: 'Restaurante', child: Row(children: [Icon(Icons.restaurant, color: Colors.green), SizedBox(width: 8), Text('Restaurante')])),
                      DropdownMenuItem(value: 'Outro', child: Row(children: [Icon(Icons.location_on, color: Colors.purple), SizedBox(width: 8), Text('Outro')])),
                    ],
                    onChanged: (valor) => setStateDialog(() => tipoSelecionado = valor!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (nomeCtrl.text.isEmpty) return;
                    
                    // 1. Gera ID do Ponto (Timestamp)
                    final String pontoId = DateTime.now().millisecondsSinceEpoch.toString();
                    
                    // 2. Busca o ID DO USUÁRIO (UUID Único)
                    final String userId = await SessionManager.getUserId();

                    final novoPonto = PontoParada(
                      id: pontoId,
                      userId: userId, // <--- Aqui está a mágica!
                      nome: nomeCtrl.text,
                      tipo: tipoSelecionado,
                      localizacao: centro,
                    );

                    await _repository.salvarPonto(novoPonto);
                    await _carregarDados();

                    if (mounted) {
                      setState(() => _modoAdicao = false);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mapa e Paradas'),
          bottom: const TabBar(tabs: [Tab(icon: Icon(Icons.map), text: 'Mapa'), Tab(icon: Icon(Icons.list), text: 'Lista')]),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!_modoAdicao)
              FloatingActionButton(
                heroTag: "btnGPS", mini: true, backgroundColor: _minhaLocalizacao == null ? Colors.grey : Colors.blue,
                onPressed: () => _moverCameraParaUsuario(),
                child: const Icon(Icons.my_location),
              ),
            const SizedBox(height: 10),
            
            if (!_modoAdicao)
              FloatingActionButton(
                heroTag: "btnAdd",
                onPressed: () {
                  setState(() => _modoAdicao = true);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arraste o mapa para posicionar a mira 🎯'), duration: Duration(seconds: 2)));
                },
                backgroundColor: Colors.orange,
                child: const Icon(Icons.add),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(heroTag: "btnCancel", mini: true, backgroundColor: Colors.red, onPressed: () => setState(() => _modoAdicao = false), child: const Icon(Icons.close)),
                  const SizedBox(width: 10),
                  FloatingActionButton.extended(heroTag: "btnConfirm", onPressed: _confirmarAdicao, backgroundColor: Colors.green, icon: const Icon(Icons.check), label: const Text('CONFIRMAR')),
                ],
              ),
          ],
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMapaOSM(),
            _buildLista(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapaOSM() {
    List<Marker> marcadores = _pontos.map((p) => Marker(
      point: p.localizacao, width: 40, height: 40,
      child: GestureDetector(
        onTap: () { if (!_modoAdicao) _mostrarDetalhes(p); },
        child: _getMarcadorVisual(p.tipo),
      ),
    )).toList();

    if (_minhaLocalizacao != null) {
      marcadores.add(Marker(point: _minhaLocalizacao!, width: 50, height: 50, child: _getMarcadorVisual('Voce')));
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(-23.5505, -46.6333), initialZoom: 14.0,
            onMapReady: () {
              _mapaPronto = true;
              if (_minhaLocalizacao != null && !_primeiraLocalizacaoRecebida) {
                _moverCameraParaUsuario();
                _primeiraLocalizacaoRecebida = true;
              }
            },
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.capivaraloka.app'),
            MarkerLayer(markers: marcadores),
          ],
        ),
        if (_modoAdicao) ...[
          Center(child: Padding(padding: const EdgeInsets.only(bottom: 40), child: Icon(Icons.location_on, size: 50, color: Colors.orange.shade800))),
          const Center(child: Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.add, size: 20, color: Colors.white))),
          Positioned(top: 20, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)), child: const Text('Posicione a mira no local desejado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
        ],
      ],
    );
  }

  Widget _getMarcadorVisual(String tipo) {
    IconData icone; Color corIcone; Color corFundo;
    switch (tipo) {
      case 'Voce': return Container(decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: const Icon(Icons.directions_car, color: Colors.white, size: 28));
      case 'Posto': icone = Icons.local_gas_station; corIcone = Colors.blue.shade900; corFundo = Colors.blue.shade100; break;
      case 'Fiscalizacao': icone = Icons.local_police; corIcone = Colors.red.shade900; corFundo = Colors.red.shade100; break;
      case 'Oficina': icone = Icons.build; corIcone = Colors.orange.shade900; corFundo = Colors.orange.shade100; break;
      case 'Restaurante': icone = Icons.restaurant; corIcone = Colors.green.shade900; corFundo = Colors.green.shade100; break;
      default: icone = Icons.location_on; corIcone = Colors.purple.shade900; corFundo = Colors.purple.shade100;
    }
    return Container(decoration: BoxDecoration(color: corFundo.withOpacity(0.9), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4)]), child: Icon(icone, color: corIcone, size: 22));
  }

  Widget _buildLista() {
    if (_pontos.isEmpty) return const Center(child: Text('Nenhum ponto salvo.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: _pontos.length,
      itemBuilder: (context, index) {
        final p = _pontos[index];
        return Dismissible(
          key: Key(p.id),
          direction: DismissDirection.endToStart,
          background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
          onDismissed: (direction) async {
            await _repository.removerPonto(p.id);
            setState(() { _pontos.removeAt(index); });
          },
          child: Card(child: ListTile(leading: _getMarcadorVisual(p.tipo), title: Text(p.nome), subtitle: Text(p.tipo), onTap: () => _mostrarDetalhes(p))),
        );
      },
    );
  }

  void _mostrarDetalhes(PontoParada p) {
    showModalBottomSheet(context: context, builder: (_) => Container(
      padding: const EdgeInsets.all(20), height: 150,
      child: Column(children: [Text(p.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20), ElevatedButton.icon(onPressed: () { Navigator.pop(context); _abrirGPS(p.localizacao); }, icon: const Icon(Icons.navigation), label: const Text('Navegar'))]),
    ));
  }
  
  void _abrirGPS(LatLng coord) async {
    final googleUrl = Uri.parse("geo:${coord.latitude},${coord.longitude}?q=${coord.latitude},${coord.longitude}");
    await launchUrl(googleUrl);
  }
}