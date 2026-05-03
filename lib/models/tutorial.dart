import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Tutorial
/// Representa un video tutorial almacenado en Firestore
class Tutorial {
  final String id;
  final String titulo;
  final String link;
  final DateTime? createdAt;

  Tutorial({
    required this.id,
    required this.titulo,
    required this.link,
    this.createdAt,
  });

  /// Crear Tutorial desde documento de Firestore
  factory Tutorial.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Tutorial(
      id: doc.id,
      titulo: data['Título'] ?? data['titulo'] ?? 'Sin título',
      link: data['Link'] ?? data['link'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convertir a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'link': link,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Extraer ID del video de YouTube desde el link
  String? get youtubeVideoId {
    // Soporta URLs como:
    // https://youtu.be/nXsy0FmMh9E
    // https://www.youtube.com/watch?v=nXsy0FmMh9E
    // https://youtu.be/nXsy0FmMh9E?si=syXx21YpXGxJ5jEa

    final uri = Uri.tryParse(link);
    if (uri == null) return null;

    // youtu.be format
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }

    // youtube.com format
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }

    return null;
  }

  /// URL de la miniatura del video de YouTube
  String get thumbnailUrl {
    final videoId = youtubeVideoId;
    if (videoId == null) return '';
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  /// URL para abrir el video en YouTube
  String get youtubeUrl {
    return link;
  }
}