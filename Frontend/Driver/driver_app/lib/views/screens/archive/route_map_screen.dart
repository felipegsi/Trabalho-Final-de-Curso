import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_route_service/open_route_service.dart';

// Define uma tela de mapa para exibir rotas entre dois pontos geográficos.
class RouteMapScreen extends StatefulWidget {
  final LatLng origin; // Coordenada de origem para a rota.
  final LatLng destination; // Coordenada de destino para a rota.

  // Construtor da classe com as coordenadas de origem e destino necessárias.
  const RouteMapScreen({super.key, required this.origin, required this.destination});

  @override
  _RouteMapScreenState createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  List<LatLng> points = []; // Lista para armazenar pontos da rota.
  List<Marker> markers = []; // Lista para armazenar marcadores no mapa.
  final MapController mapController =
      MapController(); // Controlador para manipulações programáticas do mapa.
  bool isLoading =
      false; // Indicador de estado de carregamento para controle UI.

  @override
  void initState() {
    super.initState();
    // Adiciona marcadores no mapa para os pontos de origem e destino ao iniciar o widget.
    markers.add(
      Marker(
        point: widget.origin,
        child: const Icon(Icons.location_on,
            color: Colors.red), // Marcador vermelho para a origem.
      ),
    );
    markers.add(
      Marker(
        point: widget.destination,
        child: const Icon(Icons.location_on,
            color: Colors.blue), // Marcador azul para o destino.
      ),
    );
    // Inicia a obtenção da rota entre origem e destino.
    getRoute();
  }

  // Função assíncrona para calcular a rota entre dois pontos usando OpenRouteService API.
  Future<void> getRoute() async {
    setState(() {
      isLoading = true; // Ativa o indicador de carregamento.
    });

    // Cria uma instância do cliente da OpenRouteService com uma chave API.
    final OpenRouteService client = OpenRouteService(
      apiKey: '5b3ce3597851110001cf6248b8fc3d76941643ee9de00a23820316b7',
    );

    // Realiza a solicitação para obter as coordenadas da rota entre os pontos definidos.
    final List<ORSCoordinate> routeCoordinates =
        await client.directionsRouteCoordsGet(
      startCoordinate: ORSCoordinate(
          latitude: widget.origin.latitude, longitude: widget.origin.longitude),
      endCoordinate: ORSCoordinate(
          latitude: widget.destination.latitude,
          longitude: widget.destination.longitude),
      profileOverride: ORSProfile.drivingCar,
    );

    // Atualiza o estado com os pontos da rota e desativa o indicador de carregamento.
    setState(() {
      points = routeCoordinates
          .map((coord) => LatLng(coord.latitude, coord.longitude))
          .toList();
      isLoading = false;
      // Ajusta o mapa para incluir ambos os marcadores com um zoom adequado.
      if (markers.length == 2) {
        LatLngBounds bounds =
            LatLngBounds.fromPoints([widget.origin, widget.destination]);
        mapController.fitBounds(bounds,
            options: const FitBoundsOptions(padding: EdgeInsets.all(50.0)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Constrói a interface do usuário do mapa com camadas de mapa, marcadores e rotas.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Screen'),
    ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: widget.origin, // Define o centro inicial do mapa.
              initialZoom: 13.0, // Define o zoom inicial do mapa.
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName:
                    'YourAppName/1.0', // Define o agente do usuário para requisições da TileLayer.
              ),
              MarkerLayer(markers: markers), // Camada de marcadores no mapa.
              PolylineLayer(polylines: [
                Polyline(points: points, strokeWidth: 4.0, color: Colors.blue),
                // Camada de linha para a rota calculada.
              ]),
            ],
          ),
          // Mostra um indicador de progresso enquanto a rota está sendo carregada.
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
