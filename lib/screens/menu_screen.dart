import 'package:flutter/material.dart';
import 'map.dart';
import 'profile.dart';
import 'tutorial_screen.dart';
import 'routes.dart';

/// Pantalla de menú principal (dashboard)
/// Header verde con logo + tagline, y tarjetas de acceso a cada sección.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(20),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [

                  _DashboardCard(
                    title: 'Rutas y horarios',
                    description:
                    'Consulta las rutas de recolección, horarios y puntos de disposición.',
                    icon: Icons.calendar_month,
                    accentColor: const Color(0xFFF9A825),
                    backgroundColor: const Color(0xFFFFF8E1),
                    decorationIcon: Icons.local_shipping,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RoutesScheduleScreen()),
                    ),
                  ),
                  _DashboardCard(
                    title: 'Puntos de recolección',
                    description:
                    'Encuentra los puntos de acopio más cercanos a ti.',
                    icon: Icons.location_on,
                    accentColor: const Color(0xFF00897B),
                    backgroundColor: const Color(0xFFE0F2F1),
                    decorationIcon: Icons.map,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapScreen()),
                    ),
                  ),
                  _DashboardCard(
                    title: 'Tutoriales',
                    description:
                    'Aprende sobre reciclaje, separación de residuos y más.',
                    icon: Icons.smart_display,
                    accentColor: const Color(0xFF1565C0),
                    backgroundColor: const Color(0xFFE3F2FD),
                    decorationIcon: Icons.menu_book,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TutorialsScreen()),
                    ),
                  ),
                  _DashboardCard(
                    title: 'Perfil',
                    description:
                    'Administra tu información, gestiona tu cuenta y preferencias.',
                    icon: Icons.person,
                    accentColor: const Color(0xFF2E7D32),
                    backgroundColor: const Color(0xFFE8F5E9),
                    decorationIcon: Icons.eco,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const perfil()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header verde con logo, nombre de la app y tagline
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.recycling, color: Colors.white, size: 34),
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(text: 'Reci', style: TextStyle(color: Colors.white)),
                TextSpan(
                    text: 'Ubaté',
                    style: TextStyle(color: Color(0xFFA5D6A7))),
              ],
            ),
          ),
          const Spacer(),
          const Icon(Icons.eco, color: Color(0xFFA5D6A7), size: 22),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Ubaté más limpio,\nun mejor futuro',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta individual del dashboard
class _DashboardCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final IconData decorationIcon;
  final Color accentColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.decorationIcon,
    required this.accentColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Decoración de fondo (esquina inferior)
              Positioned(
                bottom: -10,
                right: -10,
                child: Icon(
                  decorationIcon,
                  size: 70,
                  color: accentColor.withOpacity(0.12),
                ),
              ),

              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: accentColor, size: 26),
                        ),
                        const Spacer(),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}