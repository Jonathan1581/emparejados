import 'package:emparejados/models/match.model.dart';
import 'package:emparejados/models/usuario.model.dart';
import 'package:emparejados/repositories/matches.repository.dart';
import 'package:emparejados/repositories/usuarios.repository.dart';
import 'package:emparejados/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final usuariosRepositoryProvider = Provider<UsuariosRepository>((ref) {
  return UsuariosRepository();
});

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  return MatchesRepository();
});

final emparejamientoProvider =
    StateNotifierProvider<EmparejamientoNotifier, EmparejamientoState>((ref) {
  return EmparejamientoNotifier(
    ref.read(usuariosRepositoryProvider),
    ref.read(matchesRepositoryProvider),
  );
});

class EmparejamientoState {
  final List<Usuario> usuariosDisponibles;
  final List<Match> matches;
  final List<String> usuariosVistos;
  final bool isLoading;
  final String? error;
  final Usuario? usuarioActual;

  EmparejamientoState({
    this.usuariosDisponibles = const [],
    this.matches = const [],
    this.usuariosVistos = const [],
    this.isLoading = false,
    this.error,
    this.usuarioActual,
  });

  EmparejamientoState copyWith({
    List<Usuario>? usuariosDisponibles,
    List<Match>? matches,
    List<String>? usuariosVistos,
    bool? isLoading,
    String? error,
    Usuario? usuarioActual,
  }) {
    return EmparejamientoState(
      usuariosDisponibles: usuariosDisponibles ?? this.usuariosDisponibles,
      matches: matches ?? this.matches,
      usuariosVistos: usuariosVistos ?? this.usuariosVistos,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      usuarioActual: usuarioActual ?? this.usuarioActual,
    );
  }
}

class EmparejamientoNotifier extends StateNotifier<EmparejamientoState> {
  final UsuariosRepository _usuariosRepository;
  final MatchesRepository _matchesRepository;

  EmparejamientoNotifier(this._usuariosRepository, this._matchesRepository)
      : super(EmparejamientoState());

  Future<void> establecerUsuarioActual(Usuario usuario) async {
    logInfo('=== EMPAREJAMIENTO PROVIDER: Estableciendo usuario actual ===');
    logInfo('Usuario ID: ${usuario.id}');
    logInfo('Usuario género: ${usuario.genero}');
    logInfo('Usuario género interés: ${usuario.generoInteres}');
    logInfo('Usuario ubicación: ${usuario.latitud}, ${usuario.longitud}');

    state = state.copyWith(usuarioActual: usuario);
    logInfo('Usuario actual establecido en el estado');

    await _cargarUsuariosDisponibles();
    await _cargarMatches();

    logInfo('=== FIN ESTABLECER USUARIO ACTUAL ===');
  }

  Future<void> _cargarUsuariosDisponibles() async {
    logInfo('=== EMPAREJAMIENTO PROVIDER: Cargando usuarios disponibles ===');

    if (state.usuarioActual == null) {
      logWarning('Usuario actual es null, no se pueden cargar usuarios');
      return;
    }

    logInfo('Usuario actual encontrado, iniciando carga...');
    logInfo('Género de interés: ${state.usuarioActual!.generoInteres}');
    logInfo('Usuarios vistos: ${state.usuariosVistos.length}');
    logInfo('IDs de usuarios vistos: ${state.usuariosVistos}');

    state = state.copyWith(isLoading: true);
    logInfo('Estado de carga establecido en true');

    try {
      logInfo('Llamando a obtenerUsuariosParaEmparejar...');

      final usuarios = await _usuariosRepository
          .obtenerUsuariosParaEmparejar(
            state.usuarioActual!.id,
            state.usuarioActual!.generoInteres,
            state.usuariosVistos,
          )
          .first;

      logInfo('Usuarios obtenidos del repository: ${usuarios.length}');

      if (usuarios.isNotEmpty) {
        logInfo(
            'Primer usuario: ${usuarios.first.nombre} ${usuarios.first.apellido} (${usuarios.first.genero})');
        logInfo(
            'Último usuario: ${usuarios.last.nombre} ${usuarios.last.apellido} (${usuarios.last.genero})');
      } else {
        logWarning('No se obtuvieron usuarios del repository');
      }

      state = state.copyWith(
        usuariosDisponibles: usuarios,
        isLoading: false,
      );

      logInfo('Estado actualizado con ${usuarios.length} usuarios disponibles');
      logInfo(
          'Estado final: ${state.usuariosDisponibles.length} usuarios disponibles');
    } catch (e) {
      logError('Error al cargar usuarios disponibles', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      logInfo('Estado de error establecido: ${e.toString()}');
    }

    logInfo('=== FIN CARGAR USUARIOS DISPONIBLES ===');
  }

  Future<void> _cargarMatches() async {
    if (state.usuarioActual == null) {
      return;
    }

    try {
      final matches = await _matchesRepository
          .obtenerMatches(state.usuarioActual!.id)
          .first;

      state = state.copyWith(matches: matches);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> darLike(String usuarioId) async {
    if (state.usuarioActual == null) {
      return;
    }

    try {
      await _matchesRepository.darLike(
        state.usuarioActual!.id,
        usuarioId,
      );

      // Agregar usuario a la lista de vistos
      final nuevosUsuariosVistos = [...state.usuariosVistos, usuarioId];

      // Remover usuario de la lista de disponibles
      final nuevosUsuariosDisponibles = state.usuariosDisponibles
          .where((usuario) => usuario.id != usuarioId)
          .toList();

      state = state.copyWith(
        usuariosVistos: nuevosUsuariosVistos,
        usuariosDisponibles: nuevosUsuariosDisponibles,
      );

      // Recargar matches para ver si hay un nuevo match
      await _cargarMatches();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rechazarUsuario(String usuarioId) async {
    // Agregar usuario a la lista de vistos
    final nuevosUsuariosVistos = [...state.usuariosVistos, usuarioId];

    // Remover usuario de la lista de disponibles
    final nuevosUsuariosDisponibles = state.usuariosDisponibles
        .where((usuario) => usuario.id != usuarioId)
        .toList();

    state = state.copyWith(
      usuariosVistos: nuevosUsuariosVistos,
      usuariosDisponibles: nuevosUsuariosDisponibles,
    );
  }

  Future<void> superLike(String usuarioId) async {
    // Implementar super like (prioridad más alta)
    await darLike(usuarioId);
  }

  Future<void> refrescarUsuarios() async {
    logInfo('=== EMPAREJAMIENTO PROVIDER: Refrescando usuarios ===');
    logInfo(
        'Estado actual: ${state.usuariosDisponibles.length} usuarios disponibles');
    logInfo('Usuario actual: ${state.usuarioActual?.nombre ?? "null"}');

    await _cargarUsuariosDisponibles();

    logInfo(
        'Usuarios refrescados. Nuevo estado: ${state.usuariosDisponibles.length} usuarios disponibles');
    logInfo('=== FIN REFRESCAR USUARIOS ===');
  }

  // Actualizar un match específico (para marcar mensajes como leídos)
  Future<void> actualizarMatch(String matchId) async {
    try {
      logInfo('=== ACTUALIZANDO MATCH ===');
      logInfo('Match ID: $matchId');

      // Obtener el match actualizado desde Firestore
      final matchesSnapshot =
          _matchesRepository.obtenerMatches(state.usuarioActual?.id ?? '');
      final matches = await matchesSnapshot.first;

      // Encontrar y actualizar el match específico
      final matchIndex =
          state.matches.indexWhere((match) => match.id == matchId);
      if (matchIndex != -1) {
        final matchActualizado =
            matches.firstWhere((match) => match.id == matchId);
        final matchesActualizados = List<Match>.from(state.matches);
        matchesActualizados[matchIndex] = matchActualizado;

        state = state.copyWith(matches: matchesActualizados);
        logInfo('Match actualizado exitosamente');
      } else {
        logWarning('Match no encontrado en el estado local');
      }

      logInfo('=== FIN ACTUALIZAR MATCH ===');
    } catch (e) {
      logError('Error al actualizar match', e);
    }
  }

  // Actualizar un match específico con un objeto Match
  void actualizarMatchConObjeto(Match matchActualizado) {
    try {
      logInfo('=== ACTUALIZANDO MATCH CON OBJETO ===');
      logInfo('Match ID: ${matchActualizado.id}');

      // Encontrar y actualizar el match específico
      final matchIndex =
          state.matches.indexWhere((match) => match.id == matchActualizado.id);
      if (matchIndex != -1) {
        final matchesActualizados = List<Match>.from(state.matches);
        matchesActualizados[matchIndex] = matchActualizado;

        state = state.copyWith(matches: matchesActualizados);
        logInfo('Match actualizado exitosamente con objeto');
      } else {
        logWarning('Match no encontrado en el estado local');
      }

      logInfo('=== FIN ACTUALIZAR MATCH CON OBJETO ===');
    } catch (e) {
      logError('Error al actualizar match con objeto', e);
    }
  }

  Future<void> buscarPorIntereses(List<String> intereses) async {
    if (state.usuarioActual == null) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final usuarios = await _usuariosRepository.buscarUsuariosPorIntereses(
        intereses,
        state.usuarioActual!.id,
      );

      state = state.copyWith(
        usuariosDisponibles: usuarios,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> buscarUsuariosCercanos(double radioKm) async {
    if (state.usuarioActual == null) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final usuarios = await _usuariosRepository.obtenerUsuariosCercanos(
        state.usuarioActual!.ubicacion,
        radioKm,
        state.usuarioActual!.id,
      );

      state = state.copyWith(
        usuariosDisponibles: usuarios,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void limpiarError() {
    state = state.copyWith();
  }

  void resetearEstado() {
    state = EmparejamientoState();
  }
}
