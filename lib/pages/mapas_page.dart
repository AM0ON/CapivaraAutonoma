import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class MapasPage extends StatefulWidget {
  const MapasPage({super.key});

  @override
  State<MapasPage> createState() => _MapasPageState();
}

class _MapasPageState extends State<MapasPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final Uuid _uuid = const Uuid();

  LatLng _minhaLocalizacao = const LatLng(-23.5505, -46.6333);
  double _headingAtual = 0.0;
  
  LatLng? _pontoBuscaAtual;
  String _nomeBuscaAtual = "";

  bool _gpsAtivo = false;
  bool _buscando = false;
  bool _carregandoRadar = false; // <--- Loading do Overpass
  
  // Navegação
  List<LatLng> _rotaPontos = [];
  bool _navegando = false;
  bool _modoSeguir = false;
  double _distanciaRota = 0;
  double _tempoRota = 0;

  StreamSubscription<Position>? _posicaoStream;

  // Listas de Pontos
  List<Map<String, dynamic>> _pontosSalvos = [];     // Manuais
  List<Map<String, dynamic>> _pontosAutomaticos = []; // <--- Vindos da API Overpass

  @override
  void initState() {
    super.initState();
    _buscarPosicaoAtual();
    _carregarPontosSalvos();
  }

  @override
  void dispose() {
    _posicaoStream?.cancel();
    super.dispose();
  }

  // --- 1. GPS POWER ---
  Future<void> _buscarPosicaoAtual() async {
    try {
      bool servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!servicoAtivo) return;
      LocationPermission permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
        if (permissao == LocationPermission.denied) return;
      }
      final posicao = await Geolocator.getCurrentPosition();
      if(mounted) {
        setState(() {
          _minhaLocalizacao = LatLng(posicao.latitude, posicao.longitude);
          _gpsAtivo = true;
        });
        if (!_navegando && _pontoBuscaAtual == null) {
          _mapController.move(_minhaLocalizacao, 15.0);
        }
      }
      _iniciarMonitoramentoGPS();
    } catch (e) { debugPrint("Erro GPS: $e"); }
  }

  void _iniciarMonitoramentoGPS() {
    const LocationSettings locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);
    _posicaoStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        setState(() {
          _minhaLocalizacao = LatLng(position.latitude, position.longitude);
          _headingAtual = position.heading;
        });
        if (_modoSeguir) {
          _mapController.moveAndRotate(_minhaLocalizacao, 18.0, -_headingAtual);
        }
      },
      onError: (e) => debugPrint("Erro Stream GPS: $e"),
    );
  }

  // --- 2. OVERPASS API (RADAR) 📡 ---
  Future<void> _buscarRadarOverpass() async {
    setState(() => _carregandoRadar = true);
    
    // Raio de busca: 5000 metros (5km) ao redor do centro do mapa
    final center = _mapController.camera.center;
    final double radius = 5000; 

    // Query Overpass QL: Busca Postos, Restaurantes, Policia e Areas de Descanso
    final String query = """
      [out:json][timeout:25];
      (
        node["amenity"="fuel"](around:$radius, ${center.latitude}, ${center.longitude});
        node["amenity"="restaurant"](around:$radius, ${center.latitude}, ${center.longitude});
        node["highway"="rest_area"](around:$radius, ${center.latitude}, ${center.longitude});
        node["amenity"="police"](around:$radius, ${center.latitude}, ${center.longitude});
      );
      out body;
    """;

    final Uri url = Uri.parse("https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)); // utf8 para acentos
        final List elements = data['elements'];

        List<Map<String, dynamic>> novosPontos = [];

        for (var el in elements) {
          if (el['lat'] != null && el['lon'] != null) {
            final tags = el['tags'] ?? {};
            
            // Lógica de Tradução (OSM -> Capivara)
            String tipo = "Outro";
            IconData icon = Icons.place;
            Color color = Colors.grey;

            if (tags['amenity'] == 'fuel') {
              tipo = "Posto Combust.";
              icon = Icons.local_gas_station;
              color = Colors.red;
            } else if (tags['amenity'] == 'restaurant') {
              tipo = "Restaurante";
              icon = Icons.restaurant;
              color = Colors.orange;
            } else if (tags['amenity'] == 'police') {
              tipo = "Polícia";
              icon = Icons.local_police;
              color = Colors.blue;
            } else if (tags['highway'] == 'rest_area') {
              tipo = "Descanso";
              icon = Icons.hotel;
              color = Colors.purple;
            }

            String nome = tags['name'] ?? tags['brand'] ?? tipo; // Tenta pegar nome ou marca

            novosPontos.add({
              'lat': el['lat'],
              'lng': el['lon'],
              'nome': nome,
              'tipo': tipo,
              'iconCode': icon.codePoint,
              'colorValue': color.value,
              'origem': 'auto' // Marca que veio do radar
            });
          }
        }

        setState(() {
          _pontosAutomaticos = novosPontos;
          _carregandoRadar = false;
        });

        if (novosPontos.isNotEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${novosPontos.length} locais encontrados no Radar! 📡")));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhum local encontrado nesta área.")));
        }

      } else {
        throw Exception("Erro Overpass");
      }
    } catch (e) {
      debugPrint("Erro Radar: $e");
      setState(() => _carregandoRadar = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao conectar no Radar.")));
    }
  }

  // --- TRAÇAR ROTA ---
  Future<void> _tracarRota(LatLng destino) async {
    setState(() => _buscando = true);
    setState(() => _pontoBuscaAtual = null); 
    final String start = "${_minhaLocalizacao.longitude},${_minhaLocalizacao.latitude}";
    final String end = "${destino.longitude},${destino.latitude}";
    final Uri url = Uri.parse("https://router.project-osrm.org/route/v1/driving/$start;$end?geometries=geojson&overview=full");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coordinates = data['routes'][0]['geometry']['coordinates'];
        final double distanciaMetros = double.parse(data['routes'][0]['distance'].toString());
        final double duracaoSegundos = double.parse(data['routes'][0]['duration'].toString());
        List<LatLng> pontosConvertidos = coordinates.map((p) => LatLng(p[1].toDouble(), p[0].toDouble())).toList();
        setState(() {
          _rotaPontos = pontosConvertidos;
          _distanciaRota = distanciaMetros / 1000;
          _tempoRota = duracaoSegundos / 60;
          _navegando = true;
          _buscando = false;
          _modoSeguir = true; 
        });
        _mapController.moveAndRotate(_minhaLocalizacao, 18.0, -_headingAtual);
      }
    } catch (e) {
      debugPrint("Erro Rota: $e");
      setState(() => _buscando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao traçar rota.")));
    }
  }

  void _limparRota() {
    setState(() {
      _rotaPontos = [];
      _navegando = false;
      _modoSeguir = false;
      _distanciaRota = 0;
      _tempoRota = 0;
      _pontoBuscaAtual = null;
      _pontosAutomaticos = []; // Limpa o radar também pra não poluir
    });
    _mapController.moveAndRotate(_minhaLocalizacao, 15.0, 0.0);
  }

  // --- BUSCA ---
  Future<void> _realizarBusca(String query) async {
    if (query.isEmpty) return;
    setState(() => _buscando = true);
    FocusScope.of(context).unfocus();
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final response = await http.get(url, headers: {'User-Agent': 'com.capivaraloka.app'});
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final destino = LatLng(lat, lon);
          final nome = data[0]['display_name'];
          setState(() {
            _pontoBuscaAtual = destino;
            _nomeBuscaAtual = nome;
            _modoSeguir = false;
          });
          _mapController.move(destino, 16.0);
          _mostrarConfirmacaoRota(nome, destino);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Local não encontrado 😕")));
        }
      }
    } catch (e) { debugPrint("Erro busca: $e"); } finally { if(mounted) setState(() => _buscando = false); }
  }

  void _mostrarConfirmacaoRota(String nome, LatLng destino) {
    showModalBottomSheet(context: context, builder: (ctx) => Container(padding: const EdgeInsets.all(20), height: 220, child: Column(children: [const Icon(Icons.location_on, color: Colors.deepPurple, size: 40), const SizedBox(height: 10), Text(nome, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.navigation, color: Colors.white), label: const Text("INICIAR NAVEGAÇÃO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(vertical: 15)), onPressed: () { Navigator.pop(ctx); _tracarRota(destino); }))])));
  }

  // --- DADOS SALVOS ---
  Future<void> _carregarPontosSalvos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dadosJson = prefs.getString('pontos_mapa_v2');
    if (dadosJson != null) setState(() => _pontosSalvos = List<Map<String, dynamic>>.from(json.decode(dadosJson)));
  }

  Future<void> _salvarNovoPonto(String nome, String tipo, IconData iconData, Color color, LatLng point, {double? valor}) async {
    final novoPonto = {'id': _uuid.v4(), 'nome': nome, 'tipo': tipo, 'iconCode': iconData.codePoint, 'colorValue': color.value, 'lat': point.latitude, 'lng': point.longitude, 'data': DateTime.now().toIso8601String(), 'valor': valor};
    setState(() => _pontosSalvos.add(novoPonto));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pontos_mapa_v2', json.encode(_pontosSalvos));
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$tipo salvo!")));
  }

  // --- MENUS ---
  void _exibirMenuAdicionar(LatLng point) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (ctx) {
        return Container(height: 520, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))), padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))), const SizedBox(height: 20), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { Navigator.pop(ctx); _tracarRota(point); }, icon: const Icon(Icons.directions, color: Colors.white), label: const Text("IR PARA ESTE PONTO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(vertical: 12)))), const SizedBox(height: 20), const Text("Ou salvar como alerta:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 15), Expanded(child: GridView.count(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, children: [_botaoOpcao(ctx, "Blitz / Polícia", Icons.local_police, Colors.blue, point), _botaoOpcao(ctx, "Balança", Icons.scale, Colors.orange, point), _botaoOpcao(ctx, "Posto Combust.", Icons.local_gas_station, Colors.red, point), _botaoOpcao(ctx, "Posto Fiscal", Icons.gavel, Colors.brown, point), _botaoOpcao(ctx, "Pedágio", Icons.monetization_on, Colors.green, point), _botaoOpcao(ctx, "Descanso", Icons.hotel, Colors.purple, point), _botaoOpcao(ctx, "Perigo", Icons.warning, Colors.amber, point), _botaoOpcao(ctx, "Cliente", Icons.business, Colors.teal, point), _botaoOpcao(ctx, "Outro", Icons.place, Colors.grey, point)]))]));});
  }

  Widget _botaoOpcao(BuildContext context, String label, IconData icon, Color color, LatLng point) {
    return InkWell(onTap: () => _pedirDetalhesInteligente(context, label, icon, color, point), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5))), child: Icon(icon, color: color, size: 30)), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]));
  }

  void _pedirDetalhesInteligente(BuildContext context, String tipoDefault, IconData icon, Color color, LatLng point) {
    final nomeCtrl = TextEditingController(text: tipoDefault); final valorCtrl = TextEditingController(); 
    final bool pedeValor = (tipoDefault == "Posto Combust." || tipoDefault == "Pedágio");
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(tipoDefault)]), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: "Detalhes (Opcional)", hintText: "Ex: Bandeira Shell"), autofocus: !pedeValor), if (pedeValor) ...[const SizedBox(height: 15), TextField(controller: valorCtrl, decoration: InputDecoration(labelText: tipoDefault == "Pedágio" ? "Valor (R\$)" : "Preço Diesel (R\$)", prefixText: "R\$ ", border: const OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true)]]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")), ElevatedButton(onPressed: () { double? valorFinal; if (pedeValor && valorCtrl.text.isNotEmpty) { valorFinal = double.tryParse(valorCtrl.text.replaceAll(',', '.')); } Navigator.pop(ctx); Navigator.pop(context); _salvarNovoPonto(nomeCtrl.text, tipoDefault, icon, color, point, valor: valorFinal); }, style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white), child: const Text("Confirmar"))]));
  }

  // --- UI MAPA ---
  @override
  Widget build(BuildContext context) {
    // Mescla pontos manuais e automáticos para exibição
    final todosPontos = [..._pontosSalvos, ..._pontosAutomaticos];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _minhaLocalizacao,
              initialZoom: 15.0,
              onLongPress: (tapPosition, point) => _exibirMenuAdicionar(point),
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.capivaraloka.app'),
              
              if (_rotaPontos.isNotEmpty) PolylineLayer(polylines: [Polyline(points: _rotaPontos, strokeWidth: 6.0, color: Colors.blueAccent, borderColor: Colors.blue[900], borderStrokeWidth: 2.0)]),

              MarkerLayer(markers: [
                  if (_gpsAtivo)
                    Marker(
                      point: _minhaLocalizacao,
                      width: 50, height: 50,
                      child: Transform.rotate(angle: 0, child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)]), child: const Icon(Icons.navigation, color: Colors.blueAccent, size: 30))),
                    ),
                  
                  if (_pontoBuscaAtual != null)
                    Marker(point: _pontoBuscaAtual!, width: 60, height: 60, child: GestureDetector(onTap: () => _mostrarConfirmacaoRota(_nomeBuscaAtual, _pontoBuscaAtual!), child: const Icon(Icons.location_on, color: Colors.deepPurpleAccent, size: 50))),

                  if (_rotaPontos.isNotEmpty) Marker(point: _rotaPontos.last, width: 60, height: 60, child: const Icon(Icons.flag, color: Colors.green, size: 40)),

                  // RENDERIZA TODOS OS PONTOS (MANUAIS + RADAR)
                  ...todosPontos.map((ponto) {
                    final nome = ponto['nome'] ?? 'Ponto';
                    final iconCode = ponto['iconCode'] ?? Icons.location_on.codePoint;
                    final colorValue = ponto['colorValue'] ?? Colors.red.value;
                    final valor = ponto['valor'];
                    final bool isAuto = ponto['origem'] == 'auto'; // Verifica se veio do Radar

                    String tooltip = nome; if (valor != null) tooltip += "\nR\$ ${valor.toStringAsFixed(2)}";
                    
                    return Marker(
                      point: LatLng(ponto['lat'] ?? 0.0, ponto['lng'] ?? 0.0),
                      width: 60, height: 60,
                      child: GestureDetector(
                        onTap: () => _mostrarConfirmacaoRota(nome, LatLng(ponto['lat'], ponto['lng'])),
                        child: Column(
                          children: [
                            // Pontos do Radar não tem fundo branco no texto para poluir menos
                            if(!isAuto) Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)]), child: Text(nome, maxLines: 1, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                            
                            // Ícone (Menor se for radar)
                            Icon(IconData(iconCode, fontFamily: 'MaterialIcons'), color: Color(colorValue), size: isAuto ? 28 : 35)
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ]),
            ],
          ),

          Positioned(top: 50, left: 15, right: 15, child: _buildBarraBusca(context)),
          
          if (_buscando || _carregandoRadar) const Positioned(top: 105, left: 35, right: 35, child: LinearProgressIndicator()),

          // BOTÕES LATERAIS (Novo Botão Radar 📡)
          Positioned(bottom: 140, right: 15, child: Column(children: [
              // BOTÃO RADAR
              FloatingActionButton(
                heroTag: "btnRadar",
                backgroundColor: Colors.white,
                mini: true,
                onPressed: _buscarRadarOverpass, // <--- CHAMA A API OVERPASS
                child: const Icon(Icons.radar, color: Colors.purple),
              ),
              const SizedBox(height: 10),
              
              FloatingActionButton(
                heroTag: "btnFollow",
                backgroundColor: _modoSeguir ? Colors.blue : Colors.white,
                mini: true,
                onPressed: () {
                  setState(() {
                    _modoSeguir = !_modoSeguir;
                    if(_modoSeguir) { _mapController.moveAndRotate(_minhaLocalizacao, 18.0, -_headingAtual); } else { _mapController.rotate(0); }
                  });
                },
                child: Icon(_modoSeguir ? Icons.explore : Icons.my_location, color: _modoSeguir ? Colors.white : Colors.blue[800]),
              ),
              const SizedBox(height: 10),
              _botaoFlutuante(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
              const SizedBox(height: 10),
              _botaoFlutuante(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
            ])),

          Positioned(bottom: 0, left: 0, right: 0, child: _buildPainelInferior()),
        ],
      ),
    );
  }

  Widget _buildBarraBusca(BuildContext context) {
    return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]), child: Row(children: [IconButton(icon: const Icon(Icons.menu), onPressed: () { try { Scaffold.of(context).openDrawer(); } catch(e) { Navigator.pop(context); } }), Expanded(child: TextField(controller: _searchCtrl, textInputAction: TextInputAction.search, onSubmitted: (value) => _realizarBusca(value), decoration: const InputDecoration(hintText: "Buscar ou ir a um ponto...", border: InputBorder.none))), IconButton(icon: const Icon(Icons.search, color: Colors.blue), onPressed: () => _realizarBusca(_searchCtrl.text)), const SizedBox(width: 5)]));
  }
  Widget _botaoFlutuante(IconData icon, VoidCallback onTap) => FloatingActionButton(heroTag: null, onPressed: onTap, backgroundColor: Colors.white, mini: true, child: Icon(icon, color: Colors.blue[800]));
  
  Widget _buildPainelInferior() {
    if (_navegando) {
      return Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Distância", style: TextStyle(color: Colors.grey, fontSize: 12)), Text("${_distanciaRota.toStringAsFixed(1)} Km", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))]), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Tempo Est.", style: TextStyle(color: Colors.grey, fontSize: 12)), Text("${_tempoRota.toStringAsFixed(0)} Min", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))]), ElevatedButton(onPressed: _limparRota, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("ENCERRAR"))]));
    }
    // Mostra alertas manuais + automáticos no painel
    final todos = [..._pontosSalvos, ..._pontosAutomaticos];

    return Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)]), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Locais Próximos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 15), SizedBox(height: 90, child: todos.isEmpty ? const Center(child: Text("Use o RADAR 📡 ou adicione alertas.", style: TextStyle(color: Colors.grey))) : ListView.builder(scrollDirection: Axis.horizontal, itemCount: todos.length, itemBuilder: (ctx, i) { final p = todos[i]; final iconCode = p['iconCode'] ?? Icons.location_on.codePoint; final colorValue = p['colorValue'] ?? Colors.grey.value; final tipo = p['tipo'] ?? 'Ponto'; final nome = p['nome'] ?? 'Desconhecido'; return GestureDetector(onTap: () => _mostrarConfirmacaoRota(nome, LatLng(p['lat'], p['lng'])), child: _itemDestinoRecente(IconData(iconCode, fontFamily: 'MaterialIcons'), tipo, nome, Color(colorValue))); }))]));
  }
  Widget _itemDestinoRecente(IconData icon, String titulo, String info, Color cor) { return Container(width: 80, margin: const EdgeInsets.only(right: 15), child: Column(children: [CircleAvatar(radius: 25, backgroundColor: cor.withOpacity(0.1), child: Icon(icon, color: cor)), const SizedBox(height: 5), Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), Text(info, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey))])); }
}