import '../models/collection_route.dart';

/// Datos de rutas de recolección de Emservilla ESP - Ubaté
/// Fuente: Póster "Días y Horarios - Rutas de Recolección"
class RoutesData {
  static const List<CollectionRoute> noAprovechables = [
    CollectionRoute(
      day: 'Lunes',
      shift: 'Ruta de la mañana',
      startTime: '5:00 a.m.',
      description:
      'Parques Municipales (P. Libertadores, P. Ricaurte, P. JJ Neira), '
          'Hospital El Salvador de Ubaté, PTAR, Granja UDEC, Doña Leche, '
          'Conjunto residencial Las Margaritas, Plaza de Mercado, Torres de '
          'Compensar, Salida Bogotá hasta round point, Coovimpru, '
          'Urbanización Parques del Cerrito, Restaurante la Rueca, '
          'Urbanizaciones La Estanzuela y El Portal.',
      type: WasteRouteType.noAprovechables,
    ),
    CollectionRoute(
      day: 'Lunes',
      shift: 'Ruta de la tarde',
      startTime: '5:00 p.m.',
      description:
      'Plaza de Mercado, sector la Legua, Coovimpru y Santa Catalina, '
          'Todas las Calles del Municipio (desde la Calle 4 hasta la Calle '
          '12 entre las Carreras 4 a Carrera 11).',
      type: WasteRouteType.noAprovechables,
    ),
    CollectionRoute(
      day: 'Martes',
      shift: 'Ruta de la tarde 1',
      startTime: '4:00 p.m.',
      description:
      'Sector la Legua, Barrio Santa Bárbara, Barrio Viento Libre, El '
          'Cerrito, San Ignacio, Salida Bogotá (Hasta Lácteos Ubaté), '
          'Prados Cucaranga, Calderitas, Barrio San José Alto y Bajo, '
          'Barrio Villa Rosita, Parques Municipales (P. Libertadores, P. '
          'Ricaurte, P. JJ Neira), Hospital El Salvador de Ubaté.',
      type: WasteRouteType.noAprovechables,
    ),
    CollectionRoute(
      day: 'Martes',
      shift: 'Ruta de la tarde 2',
      startTime: '4:40 p.m.',
      description:
      'Talleres 2da, Doña leche, Plaza de Mercado, Vereda Sucunchoque: '
          'sector la Laja (Gimnasio Los Andes), Sector San Luis, Convento '
          'San Luis, Barrio la Legua y Barrio El Estadio, Incluyendo '
          'Cotradecun y Villa Julia.',
      type: WasteRouteType.noAprovechables,
    ),
    CollectionRoute(
      day: 'Miércoles',
      shift: 'Ruta de la tarde 1',
      startTime: '—',
      description:
      'Urbanización Margaritas, Plaza de Mercado, Sector la Legua, '
          'Barrio Norte, Barrio Centro del Llano (la vuelta al 4), Todas '
          'las Carreras del Municipio (desde la Carrera 11 hasta la Carrera '
          '4 entre calles 4 a 12).',
      type: WasteRouteType.noAprovechables,
    ),
    CollectionRoute(
      day: 'Miércoles',
      shift: 'Ruta de la tarde 2',
      startTime: '—',
      description:
      'Vereda Guantancuy: sectores alto y El Cedro, Vereda Soagá: '
          'Soagá centro y bajo, Vereda Volcán Bajo: Getsemaní, Juan Pablo '
          'II y Chircales.',
      type: WasteRouteType.noAprovechables,
    ),
    CollectionRoute(
      day: 'Jueves',
      shift: 'Ruta de la tarde 1',
      startTime: '—',
      description:
      'Plaza de mercado, sector la Legua, La Patera, Coovimpru y Santa '
          'Catalina, Todas las Calles del Municipio (desde la Calle 4 '
          'hasta la Calle 12 entre las Carreras 4 a 11).',
      type: WasteRouteType.noAprovechables,
    ),
    CollectionRoute(
      day: 'Jueves',
      shift: 'Ruta de la tarde 2',
      startTime: '—',
      description:
      'Torres de Compensar, Salida Chiquinquirá, Palogordo, Plaza del '
          'Ganado, Salida Lenguazaque, Doña Leche, Round Point '
          'Lenguazaque.',
      type: WasteRouteType.noAprovechables,
    ),
    CollectionRoute(
      day: 'Viernes',
      shift: 'Ruta de la mañana',
      startTime: '5:00 a.m.',
      description:
      'Parques Municipales (P. Libertadores, P. Ricaurte, P. JJ '
          'Neira), Hospital El Salvador de Ubaté, Unidad Básica, '
          'Cementerio, Vereda Tausavita, Carrera 2, Salida Bogotá hasta '
          'round point, Coovimpru, Urbanización Parques del Cerrito, '
          'Urbanizaciones La Estanzuela, El Portal, Plaza de Mercado.',
      type: WasteRouteType.noAprovechables,
    ),
    CollectionRoute(
      day: 'Viernes',
      shift: 'Ruta de la tarde 1',
      startTime: '—',
      description:
      'Plaza de mercado, sector La Legua, Barrio Santa Bárbara, Barrio '
          'Viento Libre, Villa Yuri, El Cerrito, San Ignacio, Salida '
          'Bogotá (Hasta Lácteos Ubaté), Prados Cucaranga, Calderitas, '
          'Barrio San José Alto y Bajo, Barrio Villa Rosita, Parques '
          'Municipales (P. Libertadores, P. Ricaurte, P. JJ Neira), '
          'Hospital El Salvador de Ubaté.',
      type: WasteRouteType.noAprovechables,
    ),
    CollectionRoute(
      day: 'Viernes',
      shift: 'Ruta de la tarde 2',
      startTime: '6:30 p.m.',
      description:
      'Barrio La Legua y Barrio El Estadio, Incluyendo Cotradecun y '
          'Villa Julia.',
      type: WasteRouteType.noAprovechables,
    ),
    CollectionRoute(
      day: 'Sábado',
      shift: null,
      startTime: '4:00 p.m.',
      description:
      'Urbanización Las Margaritas, Plaza de Mercado, Barrio Norte, '
          'Barrio Centro del Llano (la vuelta al 4), se cubre Carrera 9, '
          'Todas las Carreras del Municipio (desde la Carrera 11 hasta la '
          'Carrera 4 entre calles 4 a 12).',
      type: WasteRouteType.noAprovechables,
    ),
  ];

  static const List<CollectionRoute> organicos = [
    CollectionRoute(
      day: 'Lunes',
      shift: null,
      startTime: '2:00 p.m. / 4:00 p.m.',
      description:
      '2:00 p.m.: Ruta exclusiva para el sector comercial.\n'
          '4:00 p.m.: Barrio Norte, Barrio la Legua y Barrio El Estadio.',
      type: WasteRouteType.organicos,
    ),
    CollectionRoute(
      day: 'Martes',
      shift: null,
      startTime: '2:00 p.m. / 4:00 p.m.',
      description:
      '2:00 p.m.: Ruta exclusiva para el sector comercial.\n'
          '4:00 p.m.: Principales Calles del Municipio (desde la Carrera '
          '11 hasta la Carrera 4 entre calles 4 a 12).',
      type: WasteRouteType.organicos,
    ),
    CollectionRoute(
      day: 'Miércoles',
      shift: null,
      startTime: '2:00 p.m.',
      description: '2:00 p.m.: Ruta exclusiva para el sector comercial.',
      type: WasteRouteType.organicos,
    ),
    CollectionRoute(
      day: 'Jueves',
      shift: null,
      startTime: '2:00 p.m. / 4:00 p.m.',
      description:
      '2:00 p.m.: Ruta exclusiva para el sector comercial.\n'
          '4:00 p.m.: Parques del Cerrito, Villa Rosita, La Estanzuela, El '
          'Portal.',
      type: WasteRouteType.organicos,
    ),
    CollectionRoute(
      day: 'Viernes',
      shift: null,
      startTime: '2:00 p.m. / 4:00 p.m.',
      description:
      '2:00 p.m.: Ruta exclusiva para el sector comercial.\n'
          '4:00 p.m.: Principales Calles del Municipio (desde la Calle 4 '
          'hasta la Calle 12 entre Carreras 4 a 11), Santa Catalina.',
      type: WasteRouteType.organicos,
    ),
    CollectionRoute(
      day: 'Sábado',
      shift: null,
      startTime: '2:00 p.m.',
      description:
      '2:00 p.m.: Ruta exclusiva para el sector comercial (ida y '
          'vuelta).',
      type: WasteRouteType.organicos,
    ),
  ];
}