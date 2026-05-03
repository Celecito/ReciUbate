import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tutorial.dart';

/// Servicio para gestionar tutoriales en Firestore
class TutorialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Nombre de la colección en Firestore
  final String _collectionName = 'tutoriales';

  /// Obtener stream de tutoriales (tiempo real)
  Stream<List<Tutorial>> getTutorialsStream() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Tutorial.fromFirestore(doc))
          .toList();
    });
  }

  /// Obtener lista de tutoriales (una vez)
  Future<List<Tutorial>> getTutorials() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Tutorial.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Si no existe el campo createdAt, intentar sin ordenar
      try {
        final snapshot = await _firestore
            .collection(_collectionName)
            .get();

        return snapshot.docs
            .map((doc) => Tutorial.fromFirestore(doc))
            .toList();
      } catch (e) {
        throw Exception('Error al obtener tutoriales: $e');
      }
    }
  }

  /// Agregar un nuevo tutorial
  Future<void> addTutorial({
    required String titulo,
    required String link,
  }) async {
    try {
      final tutorial = Tutorial(
        id: '', // Se generará automáticamente
        titulo: titulo,
        link: link,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_collectionName)
          .add(tutorial.toMap());
    } catch (e) {
      throw Exception('Error al agregar tutorial: $e');
    }
  }

  /// Actualizar un tutorial existente
  Future<void> updateTutorial({
    required String id,
    required String titulo,
    required String link,
  }) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update({
        'titulo': titulo,
        'link': link,
      });
    } catch (e) {
      throw Exception('Error al actualizar tutorial: $e');
    }
  }

  /// Eliminar un tutorial
  Future<void> deleteTutorial(String id) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar tutorial: $e');
    }
  }

  /// Buscar tutoriales por título
  Future<List<Tutorial>> searchTutorials(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .get();

      final allTutorials = snapshot.docs
          .map((doc) => Tutorial.fromFirestore(doc))
          .toList();

      // Filtrar por título (búsqueda local)
      return allTutorials
          .where((tutorial) =>
          tutorial.titulo.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar tutoriales: $e');
    }
  }
}