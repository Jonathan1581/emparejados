import 'package:emparejados/screens/chat/chat.screen.dart';
import 'package:emparejados/screens/emparejamiento/emparejamiento.screen.dart';
import 'package:emparejados/screens/perfil/perfil_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_animated_navigation_bar/super_animated_navigation_bar.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const EmparejamientoScreen(),
    const ChatScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SuperAnimatedNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (mounted) {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          items: [
            NavigationBarItem(
              selectedIcon:
                  const Icon(Icons.favorite, color: Color(0xFFFF6B6B)),
              unSelectedIcon:
                  const Icon(Icons.favorite_border, color: Colors.grey),
            ),
            NavigationBarItem(
              selectedIcon:
                  const Icon(Icons.chat_bubble, color: Color(0xFFFF6B6B)),
              unSelectedIcon:
                  const Icon(Icons.chat_bubble_outline, color: Colors.grey),
            ),
            NavigationBarItem(
              selectedIcon: const Icon(Icons.person, color: Color(0xFFFF6B6B)),
              unSelectedIcon:
                  const Icon(Icons.person_outline, color: Colors.grey),
            ),
          ],
          barHeight: 70,
          indeicatorDecoration: IndeicatorDecoration(
            indeicatorColor: const Color(0xFFFF6B6B),
            glowEnable: true,
            glowColor: const Color(0xFFFF6B6B),
            glowRadius: 24,
            animateDuration: const Duration(milliseconds: 800),
          ),
        ),
      ),
    );
  }
}
