/// Tipo de residuo de la ruta
enum WasteRouteType { noAprovechables, organicos }

/// Modelo de una ruta de recolección (un turno/horario dentro de un día)
class CollectionRoute {
  final String day;
  final String? shift; // ej: "Ruta de la mañana", "Ruta de la tarde 1"
  final String startTime;
  final String description;
  final WasteRouteType type;

  const CollectionRoute({
    required this.day,
    this.shift,
    required this.startTime,
    required this.description,
    required this.type,
  });
}