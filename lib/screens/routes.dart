import 'package:flutter/material.dart';
import '../models/collection_route.dart';
import '../data/routes_data.dart';

/// Pantalla de Rutas y Horarios de recolección
/// Datos basados en el póster oficial de Emservilla ESP - Ubaté
class RoutesScheduleScreen extends StatelessWidget {
  const RoutesScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rutas y Horarios'),
          backgroundColor: const Color(0xFFF9A825),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: Icon(Icons.delete_outline),
                text: 'No Aprovechables',
              ),
              Tab(
                icon: Icon(Icons.eco_outlined),
                text: 'Orgánicos',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RoutesList(
              routes: RoutesData.noAprovechables,
              accentColor: Color(0xFF37474F),
            ),
            _RoutesList(
              routes: RoutesData.organicos,
              accentColor: Color(0xFF2E7D32),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de rutas agrupadas por día
class _RoutesList extends StatelessWidget {
  final List<CollectionRoute> routes;
  final Color accentColor;

  const _RoutesList({required this.routes, required this.accentColor});

  /// Agrupar rutas por día manteniendo el orden Lunes → Sábado
  Map<String, List<CollectionRoute>> _groupByDay() {
    const order = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado'
    ];
    final grouped = <String, List<CollectionRoute>>{};
    for (final day in order) {
      final dayRoutes = routes.where((r) => r.day == day).toList();
      if (dayRoutes.isNotEmpty) {
        grouped[day] = dayRoutes;
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return _DaySection(
          day: entry.key,
          routes: entry.value,
          accentColor: accentColor,
        );
      }).toList(),
    );
  }
}

/// Sección expandible de un día, con sus turnos/rutas
class _DaySection extends StatelessWidget {
  final String day;
  final List<CollectionRoute> routes;
  final Color accentColor;

  const _DaySection({
    required this.day,
    required this.routes,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: CircleAvatar(
            backgroundColor: accentColor,
            child: Text(
              day.substring(0, 2).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(
            day,
            style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
          ),
          subtitle: Text(
            '${routes.length} ${routes.length == 1 ? 'turno' : 'turnos'} de recolección',
            style: const TextStyle(fontSize: 12),
          ),
          children: routes.map((route) => _RouteTile(route: route, accentColor: accentColor)).toList(),
        ),
      ),
    );
  }
}

/// Detalle de un turno de recolección (hora + descripción)
class _RouteTile extends StatelessWidget {
  final CollectionRoute route;
  final Color accentColor;

  const _RouteTile({required this.route, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  route.shift != null
                      ? '${route.shift} · ${route.startTime}'
                      : route.startTime,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            route.description,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}