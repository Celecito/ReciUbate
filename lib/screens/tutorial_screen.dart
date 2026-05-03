import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tutorial.dart';
import '../services/tutorial_service.dart';

/// Pantalla de tutoriales
/// Muestra videos educativos desde Firestore
class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({super.key});

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  final TutorialService _tutorialService = TutorialService();
  final TextEditingController _searchController = TextEditingController();

  List<Tutorial> _allTutorials = [];
  List<Tutorial> _filteredTutorials = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTutorials();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Cargar tutoriales desde Firestore
  Future<void> _loadTutorials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final tutorials = await _tutorialService.getTutorials();
      setState(() {
        _allTutorials = tutorials;
        _filteredTutorials = tutorials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Filtrar tutoriales por búsqueda
  void _filterTutorials(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTutorials = _allTutorials;
      } else {
        _filteredTutorials = _allTutorials
            .where((tutorial) =>
            tutorial.titulo.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  /// Abrir video de YouTube
  Future<void> _openVideo(Tutorial tutorial) async {
    final Uri url = Uri.parse(tutorial.youtubeUrl);

    try {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutoriales'),
        backgroundColor: const Color(0xFF238501),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterTutorials,
              decoration: InputDecoration(
                hintText: 'Buscar tutoriales...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterTutorials('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Contenido principal
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadTutorials,
        backgroundColor: const Color(0xFF238501),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  /// Construir contenido según el estado
  Widget _buildContent() {
    // Loading
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF238501),
        ),
      );
    }

    // Error
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar tutoriales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTutorials,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF238501),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Lista vacía
    if (_filteredTutorials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isNotEmpty
                  ? Icons.search_off
                  : Icons.video_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No se encontraron tutoriales'
                  : 'No hay tutoriales disponibles',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _filterTutorials('');
                },
                child: const Text('Limpiar búsqueda'),
              ),
            ],
          ],
        ),
      );
    }

    // Lista de tutoriales
    return RefreshIndicator(
      onRefresh: _loadTutorials,
      color: const Color(0xFF238501),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredTutorials.length,
        itemBuilder: (context, index) {
          final tutorial = _filteredTutorials[index];
          return _buildTutorialCard(tutorial);
        },
      ),
    );
  }

  /// Construir card de tutorial
  Widget _buildTutorialCard(Tutorial tutorial) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openVideo(tutorial),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniatura del video
            Stack(
              children: [
                // Imagen de YouTube
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: tutorial.thumbnailUrl.isNotEmpty
                      ? Image.network(
                    tutorial.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.video_library,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.video_library,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                // Overlay de play
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Badge de YouTube
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'YouTube',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Información del tutorial
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    tutorial.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Fecha (si existe)
                  if (tutorial.createdAt != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(tutorial.createdAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formatear fecha
  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}