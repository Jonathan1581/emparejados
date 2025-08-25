import 'package:emparejados/screens/auth/login.screen.dart';
import 'package:emparejados/screens/auth/registro.screen.dart';
import 'package:emparejados/screens/chat/chat.screen.dart';
import 'package:emparejados/screens/configuracion/configuracion.screen.dart';
import 'package:emparejados/screens/emparejamiento/emparejamiento.screen.dart';
import 'package:emparejados/screens/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static const String login = '/login';
  static const String registro = '/registro';
  static const String main = '/main';
  static const String emparejamiento = '/emparejamiento';
  static const String chat = '/chat';
  static const String configuracion = '/configuracion';
  static const String editarPerfil = '/editar-perfil';

  static GoRouter get router => GoRouter(
        initialLocation: login,
        routes: [
          // Ruta de login
          GoRoute(
            path: login,
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),

          // Ruta de registro
          GoRoute(
            path: registro,
            name: 'registro',
            builder: (context, state) => const RegistroScreen(),
          ),

          // Ruta principal
          GoRoute(
            path: main,
            name: 'main',
            builder: (context, state) => const MainScreen(),
          ),

          // Ruta de emparejamiento
          GoRoute(
            path: emparejamiento,
            name: 'emparejamiento',
            builder: (context, state) => const EmparejamientoScreen(),
          ),

          // Ruta de chat
          GoRoute(
            path: chat,
            name: 'chat',
            builder: (context, state) => const ChatScreen(),
          ),

          // Ruta de configuración
          GoRoute(
            path: configuracion,
            name: 'configuracion',
            builder: (context, state) => const ConfiguracionScreen(),
          ),

          // Ruta de editar perfil
          // GoRoute(
          //   path: editarPerfil,
          //   name: 'editarPerfil',
          //   builder: (context, state) => const EditarPerfilScreen(),
          // ),
        ],

        // Redirecciones basadas en el estado de autenticación
        redirect: (context, state) {
          // Aquí puedes agregar lógica de redirección basada en autenticación
          // Por ahora, permitimos todas las rutas
          return null;
        },

        // Manejo de errores
        errorBuilder: (context, state) => Scaffold(
          body: Center(
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
                  'Página no encontrada: ${state.uri.path}',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go(login),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      );
}
