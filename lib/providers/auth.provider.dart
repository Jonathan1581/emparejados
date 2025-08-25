import 'package:emparejados/models/usuario.model.dart';
import 'package:emparejados/repositories/auth.repository.dart';
import 'package:emparejados/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

final usuarioActualProvider = FutureProvider<Usuario?>((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  return await authRepository.obtenerUsuarioActual();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(secureStorageProvider),
  );
});

class AuthState {
  final bool isLoading;
  final String? error;
  final Usuario? usuario;

  AuthState({
    this.isLoading = false,
    this.error,
    this.usuario,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    Usuario? usuario,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      usuario: usuario ?? this.usuario,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _secureStorage;

  AuthNotifier(this._authRepository, this._secureStorage) : super(AuthState()) {
    // Inicializar usuario si ya hay una sesión activa
    _inicializarUsuario();
  }

  Future<void> _inicializarUsuario() async {
    try {
      logInfo('AuthProvider: Inicializando usuario...');

      // Verificar si hay un usuario autenticado
      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        logInfo(
            'AuthProvider: Usuario autenticado encontrado: ${currentUser.uid}');

        // Cargar usuario desde Firestore
        final usuario = await _authRepository.obtenerUsuarioActual();
        if (usuario != null) {
          logInfo(
              'AuthProvider: Usuario cargado en inicialización: ${usuario.nombre}');
          state = state.copyWith(usuario: usuario);
        } else {
          logWarning(
              'AuthProvider: No se pudo cargar usuario en inicialización');
        }
      } else {
        logInfo('AuthProvider: No hay usuario autenticado');
      }
    } catch (e) {
      logError('AuthProvider: Error al inicializar usuario', e);
    }
  }

  Future<void> registrarUsuario(
    String email,
    String password,
    Usuario usuario,
  ) async {
    logInfo('AuthProvider: Iniciando registro de usuario con email: $email');
    state = state.copyWith(isLoading: true);

    try {
      logInfo('AuthProvider: Llamando a AuthRepository.registrarConEmail');
      await _authRepository.registrarConEmail(email, password, usuario);
      logInfo(
          'AuthProvider: Usuario registrado exitosamente en AuthRepository');
      state = state.copyWith(isLoading: false);
      logInfo('AuthProvider: Estado actualizado - isLoading = false');
    } catch (e) {
      logError('AuthProvider: Error durante el registro', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      logInfo(
          'AuthProvider: Estado actualizado - isLoading = false, error = ${e.toString()}');
      rethrow;
    }
  }

  Future<void> iniciarSesion(String email, String password,
      {bool guardarSesion = false}) async {
    logInfo('AuthProvider: Iniciando sesión con email: $email');
    state = state.copyWith(isLoading: true);

    try {
      logInfo('AuthProvider: Llamando a AuthRepository.iniciarSesion');
      await _authRepository.iniciarSesion(email, password);
      logInfo('AuthProvider: Sesión iniciada exitosamente en Firebase Auth');

      // Guardar credenciales si se solicita
      if (guardarSesion) {
        await _guardarCredenciales(email, password);
        logInfo('Credenciales guardadas en almacenamiento seguro');
      }

      // Cargar el usuario desde Firestore
      logInfo('AuthProvider: Cargando usuario desde Firestore...');
      final usuario = await _authRepository.obtenerUsuarioActual();

      if (usuario != null) {
        logInfo(
            'AuthProvider: Usuario cargado exitosamente: ${usuario.nombre} ${usuario.apellido}');
        logInfo(
            'AuthProvider: Género: ${usuario.genero}, Género interés: ${usuario.generoInteres}');
        logInfo(
            'AuthProvider: Ubicación: ${usuario.latitud}, ${usuario.longitud}');

        state = state.copyWith(
          isLoading: false,
          usuario: usuario,
        );
        logInfo('AuthProvider: Estado actualizado con usuario cargado');
      } else {
        logWarning('AuthProvider: No se pudo cargar usuario desde Firestore');
        state = state.copyWith(
          isLoading: false,
          error: 'No se pudo cargar el perfil del usuario',
        );
      }
    } catch (e) {
      logError('AuthProvider: Error durante el inicio de sesión', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> cerrarSesion() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authRepository.cerrarSesion();

      // Limpiar credenciales guardadas al cerrar sesión
      await limpiarCredencialesGuardadas();

      state = state.copyWith(
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> actualizarPerfil(Usuario usuario) async {
    state = state.copyWith(isLoading: true);

    try {
      await _authRepository.actualizarPerfil(usuario);
      state = state.copyWith(
        isLoading: false,
        usuario: usuario,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> restablecerContrasena(String email) async {
    state = state.copyWith(isLoading: true);

    try {
      await _authRepository.restablecerContrasena(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  void limpiarError() {
    state = state.copyWith();
  }

  // Métodos para almacenamiento seguro
  Future<void> _guardarCredenciales(String email, String password) async {
    try {
      await _secureStorage.write(key: 'user_email', value: email);
      await _secureStorage.write(key: 'user_password', value: password);
      await _secureStorage.write(key: 'session_saved', value: 'true');
      logInfo('Credenciales guardadas exitosamente');
    } catch (e) {
      logError('Error al guardar credenciales', e);
    }
  }

  Future<Map<String, String>?> obtenerCredencialesGuardadas() async {
    try {
      final email = await _secureStorage.read(key: 'user_email');
      final password = await _secureStorage.read(key: 'user_password');
      final sessionSaved = await _secureStorage.read(key: 'session_saved');

      if (email != null && password != null && sessionSaved == 'true') {
        return {'email': email, 'password': password};
      }
      return null;
    } catch (e) {
      logError('Error al obtener credenciales guardadas', e);
      return null;
    }
  }

  Future<void> limpiarCredencialesGuardadas() async {
    try {
      await _secureStorage.delete(key: 'user_email');
      await _secureStorage.delete(key: 'user_password');
      await _secureStorage.delete(key: 'session_saved');
      logInfo('Credenciales guardadas eliminadas');
    } catch (e) {
      logError('Error al eliminar credenciales guardadas', e);
    }
  }

  Future<bool> verificarSesionGuardada() async {
    try {
      final sessionSaved = await _secureStorage.read(key: 'session_saved');
      return sessionSaved == 'true';
    } catch (e) {
      logError('Error al verificar sesión guardada', e);
      return false;
    }
  }

  Future<bool> iniciarSesionAutomatico() async {
    try {
      logInfo('AuthProvider: Intentando inicio de sesión automático...');

      final credenciales = await obtenerCredencialesGuardadas();
      if (credenciales != null) {
        logInfo('AuthProvider: Credenciales encontradas, iniciando sesión...');

        await iniciarSesion(
          credenciales['email']!,
          credenciales['password']!,
          guardarSesion: true,
        );

        logInfo('AuthProvider: Inicio de sesión automático exitoso');
        return true;
      } else {
        logInfo('AuthProvider: No hay credenciales guardadas');
        return false;
      }
    } catch (e) {
      logError('AuthProvider: Error en inicio de sesión automático', e);
      return false;
    }
  }
}
