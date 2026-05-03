import 'package:flutter/material.dart';
import 'map.dart';
import 'education.dart';
import 'profile.dart';

class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<home> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapScreen(),
    const educacion(),
    const perfil(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Educación',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}