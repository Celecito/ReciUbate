import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Pantalla del mapa con puntos de recolección y rutas cargadas desde Firestore
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<LatLng> _navigationRoute = [];
  final LatLng _ubateCenter = const LatLng(5.3119, -73.8147);

  LatLng? _currentLocation;
  bool _isLoadingLocation = false;

  // Rutas cargadas desde Firestore
  List<CollectionRoute> _collectionRoutes = [];
  bool _isLoadingRoutes = true;
  String? _routesError;

  // Rutas cercanas al usuario (calculadas localmente)
  List<CollectionRoute> _nearbyRoutes = [];

  // Puntos fijos
  final List<CollectionPoint> _collectionPoints = [
    CollectionPoint(
      name: 'Desechar pilas',
      address: 'Cra. 8 #11-91',
      location: const LatLng(5.311328, -73.812491),
      schedule: '8:00 AM - 4:00 PM',
      type: CollectionType.pilas,
    ),
    CollectionPoint(
      name: 'Desechar aceite',
      address: 'Cra. 8 #11-91',
      location: const LatLng(5.311328, -73.812491),
      schedule: '8:00 AM - 4:00 PM',
      type: CollectionType.aceite,
    ),
    CollectionPoint(
      name: 'caneca',
      address: 'Cra. 8 #11-91',
      location: const LatLng(5.308637, -73.813890),
      schedule: '24/7',
      type: CollectionType.caneca,
    ),
    CollectionPoint(
      name: 'caneca',
      address: 'Cra. 8 #11-91',
      location: const LatLng(5.307641, -73.814497),
      schedule: '24/7',
      type: CollectionType.caneca,
    ),



  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  // ──────────────────────────────────
  // FIRESTORE: stream de rutas
  // ──────────────────────────────────

  /// Escucha en tiempo real la colección 'collection_routes'.
  /// Solo trae documentos con active == true.
  Stream<List<CollectionRoute>> get _routesStream => _db
      .collection('collection_routes')
      .where('active', isEqualTo: true)
      .snapshots()
      .map((snap) =>
      snap.docs.map((doc) => CollectionRoute.fromFirestore(doc)).toList());

  // ──────────────────────────────────
  // LÓGICA DE PROXIMIDAD
  // ──────────────────────────────────

  double _distanceToRoute(LatLng user, CollectionRoute route) {
    const Distance calc = Distance();
    double min = double.infinity;
    for (final p in route.points) {
      final d = calc.as(LengthUnit.Meter, user, p);
      if (d < min) min = d;
    }
    return min;
  }

  void _recalculateNearbyRoutes() {
    if (_currentLocation == null) return;
    final nearby = _collectionRoutes
        .where((r) => _distanceToRoute(_currentLocation!, r) <= r.proximityRadiusMeters)
        .toList()
      ..sort((a, b) => _distanceToRoute(_currentLocation!, a)
          .compareTo(_distanceToRoute(_currentLocation!, b)));
    setState(() => _nearbyRoutes = nearby);
  }

  // ──────────────────────────────────
  // UBICACIÓN
  // ──────────────────────────────────

  Future<void> _checkLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied) return;
    }
    if (p == LocationPermission.deniedForever) return;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _isLoadingLocation = false;
      });
      _mapController.move(_currentLocation!, 15.0);
      _recalculateNearbyRoutes();

      if (mounted) {
        if (_nearbyRoutes.isNotEmpty) {
          _showNearbyRoutesSheet(_nearbyRoutes);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No hay rutas de recolección cercanas a tu ubicación'),
            duration: Duration(seconds: 3),
          ));
        }
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ──────────────────────────────────
  // NAVEGACIÓN
  // ──────────────────────────────────

  Future<void> _getRoute(LatLng destination) async {
    if (_currentLocation == null) return;
    const apiKey =
        "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImM1YWE3YWZiN2Y5MjQ4YzFhNGFlYzg0Njc4Njc2ZDEwIiwiaCI6Im11cm11cjY0In0=";
    final url =
        "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey"
        "&start=${_currentLocation!.longitude},${_currentLocation!.latitude}"
        "&end=${destination.longitude},${destination.latitude}";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data["features"][0]["geometry"]["coordinates"] as List;
      setState(() {
        _navigationRoute =
            coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
      });
    }
  }

  // ──────────────────────────────────
  // BUILD
  // ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CollectionRoute>>(
      stream: _routesStream,
      builder: (context, snapshot) {
        // Actualizar lista de rutas cuando Firestore emite cambios
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _collectionRoutes = snapshot.data!;
              _isLoadingRoutes = false;
              _routesError = null;
            });
            _recalculateNearbyRoutes();
          });
        } else if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _routesError = snapshot.error.toString();
              _isLoadingRoutes = false;
            });
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mapa puntos de recolección'),
            backgroundColor: const Color(0xFF238501),
            foregroundColor: Colors.white,
            actions: [
              if (_currentLocation != null)
                IconButton(
                  icon: Badge(
                    isLabelVisible: _nearbyRoutes.isNotEmpty,
                    label: Text('${_nearbyRoutes.length}'),
                    child: const Icon(Icons.route),
                  ),
                  tooltip: 'Rutas cercanas',
                  onPressed: () => _nearbyRoutes.isNotEmpty
                      ? _showNearbyRoutesSheet(_nearbyRoutes)
                      : ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('No hay rutas cercanas a tu ubicación'))),
                ),
              IconButton(
                icon: const Icon(Icons.list),
                tooltip: 'Ver lista de puntos',
                onPressed: _showPointsList,
              ),
            ],
          ),
          body: Stack(
            children: [
              // ── MAPA ──
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _ubateCenter,
                  initialZoom: 14.0,
                  minZoom: 12.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app_reci_ubate',
                    tileBuilder: (ctx, w, t) => ColorFiltered(
                      colorFilter: ColorFilter.mode(
                          Colors.grey.withOpacity(0.1), BlendMode.saturation),
                      child: w,
                    ),
                  ),

                  // Rutas de Firestore
                  if (_collectionRoutes.isNotEmpty)
                    PolylineLayer(
                      polylines: _collectionRoutes.map((route) {
                        final isNearby = _nearbyRoutes.any((r) => r.id == route.id);
                        return Polyline(
                          points: route.points,
                          strokeWidth: isNearby ? 6.0 : 3.5,
                          color: isNearby
                              ? route.color
                              : route.color.withOpacity(0.4),
                          pattern: isNearby
                              ? const StrokePattern.solid()
                              : StrokePattern.dashed(segments: [8, 6]),
                        );
                      }).toList(),
                    ),

                  // Ruta de navegación
                  if (_navigationRoute.isNotEmpty)
                    PolylineLayer(polylines: [
                      Polyline(
                          points: _navigationRoute,
                          strokeWidth: 5,
                          color: const Color(0xFF238501))
                    ]),

                  // Marcadores inicio/fin de rutas
                  MarkerLayer(
                    markers: _collectionRoutes.expand((route) {
                      if (route.points.length < 2) return <Marker>[];
                      return [
                        _endpointMarker(
                            route.points.first, route.color, Icons.play_arrow, route),
                        _endpointMarker(
                            route.points.last, route.color, Icons.stop, route),
                      ];
                    }).toList(),
                  ),

                  // Marcadores puntos fijos
                  MarkerLayer(
                    markers: _collectionPoints.map(_buildPointMarker).toList(),
                  ),

                  // Marcador usuario
                  if (_currentLocation != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 60,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.3),
                              shape: BoxShape.circle),
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 4))
                              ],
                            ),
                            child: const Icon(Icons.my_location,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ]),
                ],
              ),

              // ── INDICADOR CARGA RUTAS ──
              if (_isLoadingRoutes)
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8)
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Cargando rutas...', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── ERROR RUTAS ──
              if (_routesError != null)
                Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Error al cargar rutas. Verifica tu conexión.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.red.shade700)),
                      ),
                    ]),
                  ),
                ),

              // ── BANNER RUTAS CERCANAS ──
              if (_nearbyRoutes.isNotEmpty && _currentLocation != null)
                Positioned(
                  bottom: 110,
                  left: 16,
                  right: 70,
                  child: GestureDetector(
                    onTap: () => _showNearbyRoutesSheet(_nearbyRoutes),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF238501).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.route,
                              color: Color(0xFF238501), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_nearbyRoutes.length} ruta${_nearbyRoutes.length > 1 ? 's' : ''} cerca de ti',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                _nearbyRoutes.map((r) => r.name).join(' · '),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Color(0xFF238501), size: 20),
                      ]),
                    ),
                  ),
                ),

              // ── FABs ──
              Positioned(
                right: 16,
                bottom: 100,
                child: FloatingActionButton(
                  heroTag: 'location',
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  backgroundColor: Colors.white,
                  child: _isLoadingLocation
                      ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, color: Color(0xFF238501)),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 32,
                child: FloatingActionButton(
                  heroTag: 'center',
                  onPressed: () => _mapController.move(_ubateCenter, 14.0),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.center_focus_strong,
                      color: Color(0xFF238501)),
                ),
              ),

              // ── LEYENDA ──
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Leyenda',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            ...CollectionType.values.map((t) =>
                                _chip(t.label, t.color, t.icon)),
                            ..._collectionRoutes.map((r) =>
                                _chip(r.name, r.color, Icons.route)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────
  // WIDGETS AUXILIARES
  // ──────────────────────────────────

  Widget _chip(String label, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  Marker _buildPointMarker(CollectionPoint point) => Marker(
    point: point.location,
    width: 40,
    height: 40,
    child: GestureDetector(
      onTap: () => _showPointDetails(point),
      child: Container(
        decoration: BoxDecoration(
          color: point.type.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Icon(point.type.icon, color: Colors.white, size: 20),
      ),
    ),
  );

  Marker _endpointMarker(
      LatLng point, Color color, IconData icon, CollectionRoute route) =>
      Marker(
        point: point,
        width: 28,
        height: 28,
        child: GestureDetector(
          onTap: () => _showRouteDetails(route),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
        ),
      );

  Widget _detailRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Colors.grey[600]),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700])),
      ),
    ],
  );

  // ──────────────────────────────────
  // BOTTOM SHEETS
  // ──────────────────────────────────

  void _showNearbyRoutesSheet(List<CollectionRoute> routes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF238501).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.route, color: Color(0xFF238501), size: 22),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Rutas cercanas a ti',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                    '${routes.length} ruta${routes.length > 1 ? 's' : ''} encontrada${routes.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ]),
            ]),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ...routes.map((r) => _buildRouteCard(
                r,
                _currentLocation != null
                    ? _distanceToRoute(_currentLocation!, r).round()
                    : 0)),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(CollectionRoute route, int distMeters) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: route.color.withOpacity(0.4)),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pop(context);
        if (route.points.isNotEmpty) {
          _mapController.move(route.points.first, 15.0);
        }
        Future.delayed(const Duration(milliseconds: 300),
                () => _showRouteDetails(route));
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: route.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
            Icon(Icons.directions_bus, color: route.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(route.description,
                    style:
                    TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(route.schedule,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ],
            ),
          ),
          Column(children: [
            Text(
              distMeters < 1000
                  ? '${distMeters}m'
                  : '${(distMeters / 1000).toStringAsFixed(1)}km',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: route.color),
            ),
            Text('de ti',
                style:
                TextStyle(fontSize: 10, color: Colors.grey[500])),
          ]),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
        ]),
      ),
    ),
  );

  void _showRouteDetails(CollectionRoute route) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                      color: route.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(route.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text(route.description,
                style: TextStyle(fontSize: 15, color: Colors.grey[700])),
            const SizedBox(height: 16),
            _detailRow(Icons.access_time, route.schedule),
            const SizedBox(height: 8),
            _detailRow(Icons.pin_drop, '${route.points.length} paradas en la ruta'),
            const SizedBox(height: 8),
            _detailRow(
              Icons.social_distance,
              _currentLocation != null
                  ? 'A ${_distanceToRoute(_currentLocation!, route).round()} metros de ti'
                  : 'Activa tu ubicación para ver la distancia',
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                if (route.points.isNotEmpty) _getRoute(route.points.first);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: route.color,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.directions),
              label: const Text('Cómo llegar al inicio de la ruta',
                  style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPointDetails(CollectionPoint point) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: point.type.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(point.type.icon, size: 16, color: point.type.color),
                const SizedBox(width: 6),
                Text(point.type.label,
                    style: TextStyle(
                        color: point.type.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 16),
            Text(point.name,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _detailRow(Icons.location_on, point.address),
            const SizedBox(height: 8),
            _detailRow(Icons.access_time, point.schedule),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _mapController.move(point.location, 17.0);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF238501)),
                  ),
                  icon: const Icon(Icons.map, color: Color(0xFF238501)),
                  label: const Text('Ver en mapa',
                      style: TextStyle(color: Color(0xFF238501))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _getRoute(point.location);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF238501),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.directions),
                  label: const Text('Cómo llegar'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showPointsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(children: [
                Icon(Icons.location_on, color: Color(0xFF238501)),
                SizedBox(width: 8),
                Text('Puntos de Recolección',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _collectionPoints.length,
                itemBuilder: (context, index) {
                  final point = _collectionPoints[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: point.type.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(point.type.icon, color: point.type.color),
                      ),
                      title: Text(point.name,
                          style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(point.address),
                          const SizedBox(height: 4),
                          Text(point.schedule,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ),
                      trailing:
                      const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        _mapController.move(point.location, 17.0);
                        Future.delayed(const Duration(milliseconds: 500),
                                () => _showPointDetails(point));
                      },
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// MODELOS
// ══════════════════════════════════════════════════════

/// Ruta de recolección cargada desde Firestore
class CollectionRoute {
  final String id;
  final String name;
  final String description;
  final List<LatLng> points;
  final Color color;
  final String schedule;
  final double proximityRadiusMeters;

  const CollectionRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.color,
    required this.schedule,
    this.proximityRadiusMeters = 400,
  });

  /// Estructura esperada en Firestore (colección: collection_routes):
  ///
  /// {
  ///   "name"                 : "Ruta Norte",
  ///   "description"          : "Barrios La Esperanza...",
  ///   "schedule"             : "Lunes, Miércoles y Viernes: 6:00 AM - 10:00 AM",
  ///   "color"                : 4294944000,   // int → Colors.orange.value
  ///   "proximityRadiusMeters": 400,
  ///   "active"               : true,
  ///   "points": [
  ///     { "lat": 5.3210, "lng": -73.8180 },
  ///     { "lat": 5.3195, "lng": -73.8165 }
  ///   ]
  /// }
  factory CollectionRoute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawPoints = data['points'] as List<dynamic>? ?? [];
    final points = rawPoints.map((p) {
      final gp = p as GeoPoint;
      return LatLng(gp.latitude, gp.longitude);
    }).toList();

    return CollectionRoute(
      id: doc.id,
      name: data['name'] as String? ?? 'Sin nombre',
      description: data['description'] as String? ?? '',
      schedule: data['schedule'] as String? ?? 'Sin horario',
      color: Color(data['color'] as int? ?? 0xFF238501),
      proximityRadiusMeters:
      (data['proximityRadiusMeters'] as num?)?.toDouble() ?? 400,
      points: points,
    );
  }
}

class CollectionPoint {
  final String name;
  final String address;
  final LatLng location;
  final String schedule;
  final CollectionType type;

  CollectionPoint({
    required this.name,
    required this.address,
    required this.location,
    required this.schedule,
    required this.type,
  });
}

enum CollectionType {
  caneca,
  pilas,
  aceite;




  String get label {
    switch (this) {
      case CollectionType.caneca: return 'Caneca de basura';
      case CollectionType.pilas:  return 'Pilas';
      case CollectionType.aceite: return 'Aceite';

    }
  }

  IconData get icon {
    switch (this) {
      case CollectionType.caneca: return Icons.delete_outline;
      case CollectionType.pilas:  return Icons.battery_saver_outlined;
      case CollectionType.aceite: return Icons.oil_barrel;

    }
  }

  Color get color {
    switch (this) {
      case CollectionType.caneca: return Colors.lightGreen;
      case CollectionType.pilas:  return Colors.red;
      case CollectionType.aceite: return Colors.yellow;

    }
  }
}