import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emparejados/models/match.model.dart';
import 'package:emparejados/utils/logger.dart';

class MatchesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear o actualizar like
  Future<void> darLike(String usuarioActualId, String usuarioObjetivoId) async {
    try {
      logInfo('=== MATCHES REPOSITORY: Procesando like ===');
      logInfo('Usuario actual ID: $usuarioActualId');
      logInfo('Usuario objetivo ID: $usuarioObjetivoId');

      final matchRef = _firestore.collection('matches');
      logInfo('Referencia a collection matches creada');

      // Buscar si ya existe un match entre estos usuarios
      logInfo('Buscando match existente...');
      final querySnapshot = await matchRef.where('usuario1Id', whereIn: [
        usuarioActualId,
        usuarioObjetivoId
      ]).where('usuario2Id',
          whereIn: [usuarioActualId, usuarioObjetivoId]).get();

      logInfo(
          'Query ejecutada, documentos encontrados: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isNotEmpty) {
        logInfo('Match existente encontrado, actualizando...');
        // Actualizar match existente
        final doc = querySnapshot.docs.first;

        // Log de los datos del documento antes de procesar
        logInfo('Datos del documento: ${doc.data()}');

        try {
          final match = Match.fromFirestore(doc);
          logInfo(
              'Match existente: usuario1Id=${match.usuario1Id}, usuario2Id=${match.usuario2Id}');
          logInfo(
              'Estado actual: usuario1Liked=${match.usuario1Liked}, usuario2Liked=${match.usuario2Liked}');

          if (match.usuario1Id == usuarioActualId) {
            logInfo('Actualizando usuario1Liked = true');
            await doc.reference.update({'usuario1Liked': true});
          } else {
            logInfo('Actualizando usuario2Liked = true');
            await doc.reference.update({'usuario2Liked': true});
          }

          // Verificar si es un match completo
          final usuario1Liked =
              match.usuario1Id == usuarioActualId || match.usuario1Liked;
          final usuario2Liked =
              match.usuario2Id == usuarioActualId || match.usuario2Liked;

          logInfo(
              'Estado de likes: usuario1Liked=$usuario1Liked, usuario2Liked=$usuario2Liked');

          if (usuario1Liked && usuario2Liked) {
            logInfo('¡MATCH COMPLETO! Actualizando esMatch = true');
            await doc.reference.update({
              'esMatch': true,
              'fechaMatch': FieldValue.serverTimestamp(),
            });
          } else {
            logInfo('No es match completo aún');
          }
        } catch (parseError) {
          logError('Error al parsear documento de Firestore', parseError);
          logInfo('Documento problemático: ${doc.data()}');

          // Intentar limpiar el documento corrupto
          logInfo('Intentando limpiar documento corrupto...');
          await doc.reference.delete();
          logInfo('Documento corrupto eliminado, creando nuevo...');

          // Crear nuevo match limpio
          await _crearNuevoMatch(usuarioActualId, usuarioObjetivoId);
        }
      } else {
        logInfo('No existe match, creando nuevo...');
        await _crearNuevoMatch(usuarioActualId, usuarioObjetivoId);
      }

      logInfo('=== FIN PROCESAR LIKE ===');
    } catch (e) {
      logError('Error al dar like', e);
      rethrow;
    }
  }

  // Método helper para crear nuevo match
  Future<void> _crearNuevoMatch(
      String usuarioActualId, String usuarioObjetivoId) async {
    final matchRef = _firestore.collection('matches');

    final match = Match(
      id: '',
      usuario1Id: usuarioActualId,
      usuario2Id: usuarioObjetivoId,
      fechaMatch: DateTime.now(),
      usuario1Liked: true,
      usuario2Liked: false,
    );

    logInfo(
        'Nuevo match creado: usuario1Id=${match.usuario1Id}, usuario2Id=${match.usuario2Id}');
    await matchRef.add(match.toFirestore());
    logInfo('Nuevo match guardado en Firestore');
  }

  // Obtener matches del usuario (bidireccionales)
  Stream<List<Match>> obtenerMatches(String usuarioId) {
    try {
      logInfo('Obteniendo matches para usuario: $usuarioId');

      return _firestore
          .collection('matches')
          .where('esMatch', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        final matches = snapshot.docs.map(Match.fromFirestore).toList();

        // Filtrar solo los matches donde el usuario participa
        final matchesDelUsuario = matches.where((match) {
          return match.usuario1Id == usuarioId || match.usuario2Id == usuarioId;
        }).toList();

        logInfo('Matches encontrados: ${matchesDelUsuario.length}');
        return matchesDelUsuario;
      });
    } catch (e) {
      logError('Error al obtener matches', e);
      return Stream.value([]);
    }
  }

  // Obtener todos los matches (incluyendo likes unidireccionales)
  Stream<List<Match>> obtenerTodosLosMatches(String usuarioId) {
    try {
      return _firestore
          .collection('matches')
          .where('usuario1Id', isEqualTo: usuarioId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map(Match.fromFirestore).toList();
      });
    } catch (e) {
      logError('Error al obtener todos los matches', e);
      return Stream.value([]);
    }
  }

  // Obtener usuarios que han dado like al usuario actual
  Stream<List<String>> obtenerUsuariosQueMeGustan(String usuarioId) {
    try {
      return _firestore
          .collection('matches')
          .where('usuario2Id', isEqualTo: usuarioId)
          .where('usuario2Liked', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .where((doc) => doc.data()['usuario1Liked'] == true)
            .map((doc) => doc.data()['usuario1Id'] as String)
            .toList();
      });
    } catch (e) {
      logError('Error al obtener usuarios que me gustan', e);
      return Stream.value([]);
    }
  }

  // Obtener notificaciones de nuevos likes (para mostrar en chat)
  Stream<List<Match>> obtenerNotificacionesLikes(String usuarioId) {
    try {
      logInfo('Obteniendo notificaciones de likes para usuario: $usuarioId');

      return _firestore
          .collection('matches')
          .where('usuario2Id', isEqualTo: usuarioId)
          .where('usuario1Liked', isEqualTo: true)
          .where('usuario2Liked', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        final notificaciones = snapshot.docs.map(Match.fromFirestore).toList();
        logInfo(
            'Notificaciones de likes encontradas: ${notificaciones.length}');
        return notificaciones;
      });
    } catch (e) {
      logError('Error al obtener notificaciones de likes', e);
      return Stream.value([]);
    }
  }

  // Eliminar match
  Future<void> eliminarMatch(String matchId) async {
    try {
      logInfo('Eliminando match con ID: $matchId');
      await _firestore.collection('matches').doc(matchId).delete();
      logInfo('Match eliminado exitosamente');
    } catch (e) {
      logError('Error al eliminar match', e);
      rethrow;
    }
  }

  // Actualizar match después de dar like de vuelta
  Future<void> actualizarMatchDespuesDelike(String matchId) async {
    try {
      logInfo('Actualizando match después de dar like de vuelta: $matchId');

      // Buscar el match por ID
      final doc = await _firestore.collection('matches').doc(matchId).get();

      if (!doc.exists) {
        logError('Match no encontrado con ID: $matchId');
        return;
      }

      // Actualizar a match completo
      await doc.reference.update({
        'usuario2Liked': true,
        'esMatch': true,
        'fechaMatch': FieldValue.serverTimestamp(),
      });

      logInfo('Match actualizado exitosamente a match completo');
    } catch (e) {
      logError('Error al actualizar match después de dar like', e);
      rethrow;
    }
  }

  // Obtener estadísticas de matches
  Future<Map<String, int>> obtenerEstadisticasMatches(String usuarioId) async {
    try {
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('usuario1Id', isEqualTo: usuarioId)
          .get();

      int totalLikes = 0;
      int totalMatches = 0;
      int likesRecibidos = 0;

      for (final doc in matchesSnapshot.docs) {
        final match = Match.fromFirestore(doc);
        if (match.usuario1Liked) {
          totalLikes++;
        }
        if (match.esMatch) {
          totalMatches++;
        }
      }

      // Obtener likes recibidos
      final likesRecibidosSnapshot = await _firestore
          .collection('matches')
          .where('usuario2Id', isEqualTo: usuarioId)
          .where('usuario1Liked', isEqualTo: true)
          .get();

      likesRecibidos = likesRecibidosSnapshot.docs.length;

      return {
        'likesDados': totalLikes,
        'matches': totalMatches,
        'likesRecibidos': likesRecibidos,
      };
    } catch (e) {
      logError('Error al obtener estadísticas', e);
      return {
        'likesDados': 0,
        'matches': 0,
        'likesRecibidos': 0,
      };
    }
  }
}
