import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emparejados/models/interaccion_usuario.model.dart';
import 'package:emparejados/models/match.model.dart';
import 'package:emparejados/utils/logger.dart';

class InteraccionesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registrar una nueva interacción
  Future<void> registrarInteraccion(InteraccionUsuario interaccion) async {
    try {
      logInfo('=== REGISTRANDO INTERACCIÓN ===');
      logInfo('Usuario actual: ${interaccion.usuarioActualId}');
      logInfo('Usuario objetivo: ${interaccion.usuarioObjetivoId}');
      logInfo('Tipo: ${interaccion.tipo.name}');

      // Crear ID compuesto para evitar duplicados
      final idCompuesto = InteraccionUsuario.crearIdCompuesto(
        interaccion.usuarioActualId,
        interaccion.usuarioObjetivoId,
      );

      // Crear nueva interacción directamente (Firestore maneja duplicados)
      logInfo('Creando nueva interacción con ID: $idCompuesto');
      final docRef =
          _firestore.collection('interacciones_usuario').doc(idCompuesto);

      await docRef.set(interaccion.toFirestore(), SetOptions(merge: true));

      // Si es un like, verificar si hay match
      if (interaccion.tipo == TipoInteraccion.like ||
          interaccion.tipo == TipoInteraccion.superLike) {
        await _verificarYCrearMatch(interaccion);
      }

      logInfo('=== INTERACCIÓN REGISTRADA EXITOSAMENTE ===');
    } catch (e) {
      logError('Error al registrar interacción', e);

      // Manejo específico de errores de permisos
      if (e.toString().contains('permission-denied')) {
        throw Exception(
            'No tienes permisos para realizar esta acción. Verifica que estés autenticado correctamente.');
      } else if (e.toString().contains('unavailable')) {
        throw Exception(
            'Servicio temporalmente no disponible. Intenta nuevamente en unos momentos.');
      }

      rethrow;
    }
  }

  // Verificar si existe match y crearlo si es necesario
  Future<void> _verificarYCrearMatch(InteraccionUsuario interaccion) async {
    try {
      logInfo('Verificando si existe match...');

      // Buscar si el usuario objetivo ya dio like al usuario actual
      final querySnapshot = await _firestore
          .collection('interacciones_usuario')
          .where('usuarioActualId', isEqualTo: interaccion.usuarioObjetivoId)
          .where('usuarioObjetivoId', isEqualTo: interaccion.usuarioActualId)
          .where('tipo', whereIn: ['like', 'superLike']).get();

      if (querySnapshot.docs.isNotEmpty) {
        logInfo('¡MATCH DETECTADO! Creando match...');

        // Crear match en la colección matches
        final match = Match(
          id: '',
          usuario1Id: interaccion.usuarioActualId,
          usuario2Id: interaccion.usuarioObjetivoId,
          fechaMatch: DateTime.now(),
          usuario1Liked: true,
          usuario2Liked: true,
          esMatch: true,
        );

        final matchRef =
            await _firestore.collection('matches').add(match.toFirestore());

        // Actualizar ambas interacciones con el matchId
        final idCompuesto1 = InteraccionUsuario.crearIdCompuesto(
          interaccion.usuarioActualId,
          interaccion.usuarioObjetivoId,
        );
        final idCompuesto2 = InteraccionUsuario.crearIdCompuesto(
          interaccion.usuarioObjetivoId,
          interaccion.usuarioActualId,
        );

        await _firestore
            .collection('interacciones_usuario')
            .doc(idCompuesto1)
            .update({
          'esReciproco': true,
          'matchId': matchRef.id,
        });

        await _firestore
            .collection('interacciones_usuario')
            .doc(idCompuesto2)
            .update({
          'esReciproco': true,
          'matchId': matchRef.id,
        });

        logInfo('Match creado exitosamente con ID: ${matchRef.id}');
      } else {
        logInfo('No hay match aún, esperando reciprocidad...');
      }
    } catch (e) {
      logError('Error al verificar match', e);
    }
  }

  // Obtener todas las interacciones de un usuario
  Stream<List<InteraccionUsuario>> obtenerInteraccionesUsuario(
      String usuarioId) {
    try {
      return _firestore
          .collection('interacciones_usuario')
          .where('usuarioActualId', isEqualTo: usuarioId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map(InteraccionUsuario.fromFirestore).toList();
      });
    } catch (e) {
      logError('Error al obtener interacciones del usuario', e);
      return Stream.value([]);
    }
  }

  // Obtener usuarios que ya han sido vistos (likes, dislikes, etc.)
  Stream<List<String>> obtenerUsuariosVistos(String usuarioId) {
    try {
      return _firestore
          .collection('interacciones_usuario')
          .where('usuarioActualId', isEqualTo: usuarioId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => doc.data()['usuarioObjetivoId'] as String)
            .toList();
      });
    } catch (e) {
      logError('Error al obtener usuarios vistos', e);
      return Stream.value([]);
    }
  }

  // Obtener usuarios que han dado like al usuario actual
  Stream<List<String>> obtenerUsuariosQueMeGustan(String usuarioId) {
    try {
      return _firestore
          .collection('interacciones_usuario')
          .where('usuarioObjetivoId', isEqualTo: usuarioId)
          .where('tipo', whereIn: ['like', 'superLike'])
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => doc.data()['usuarioActualId'] as String)
                .toList();
          });
    } catch (e) {
      logError('Error al obtener usuarios que me gustan', e);
      return Stream.value([]);
    }
  }

  // Obtener estadísticas de interacciones
  Future<Map<String, int>> obtenerEstadisticasInteracciones(
      String usuarioId) async {
    try {
      final interaccionesSnapshot = await _firestore
          .collection('interacciones_usuario')
          .where('usuarioActualId', isEqualTo: usuarioId)
          .get();

      int totalLikes = 0;
      int totalDislikes = 0;
      int totalSuperLikes = 0;
      int totalMatches = 0;

      for (final doc in interaccionesSnapshot.docs) {
        final tipo = doc.data()['tipo'] as String;
        final esReciproco = doc.data()['esReciproco'] as bool? ?? false;

        switch (tipo) {
          case 'like':
            totalLikes++;
            if (esReciproco) {
              totalMatches++;
            }
            break;
          case 'dislike':
            totalDislikes++;
            break;
          case 'superLike':
            totalSuperLikes++;
            if (esReciproco) {
              totalMatches++;
            }
            break;
        }
      }

      return {
        'likes': totalLikes,
        'dislikes': totalDislikes,
        'superLikes': totalSuperLikes,
        'matches': totalMatches,
      };
    } catch (e) {
      logError('Error al obtener estadísticas de interacciones', e);
      return {
        'likes': 0,
        'dislikes': 0,
        'superLikes': 0,
        'matches': 0,
      };
    }
  }

  // Eliminar interacción (para casos de arrepentimiento)
  Future<void> eliminarInteraccion(
      String usuarioActualId, String usuarioObjetivoId) async {
    try {
      final idCompuesto = InteraccionUsuario.crearIdCompuesto(
        usuarioActualId,
        usuarioObjetivoId,
      );

      await _firestore
          .collection('interacciones_usuario')
          .doc(idCompuesto)
          .delete();

      logInfo('Interacción eliminada exitosamente');
    } catch (e) {
      logError('Error al eliminar interacción', e);
      rethrow;
    }
  }

  // Limpiar todas las interacciones de un usuario
  Future<void> limpiarInteraccionesUsuario(String usuarioId) async {
    try {
      logInfo('=== LIMPIANDO INTERACCIONES DEL USUARIO ===');
      logInfo('Usuario ID: $usuarioId');

      // Obtener todas las interacciones donde el usuario es actual o objetivo
      // Usar dos consultas separadas ya que Firestore no soporta OR en una sola consulta
      final querySnapshot1 = await _firestore
          .collection('interacciones_usuario')
          .where('usuarioActualId', isEqualTo: usuarioId)
          .get();

      final querySnapshot2 = await _firestore
          .collection('interacciones_usuario')
          .where('usuarioObjetivoId', isEqualTo: usuarioId)
          .get();

      final allDocs = [...querySnapshot1.docs, ...querySnapshot2.docs];

      logInfo('Interacciones encontradas: ${allDocs.length}');

      // Eliminar todas las interacciones en batch
      final batch = _firestore.batch();
      for (final doc in allDocs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      logInfo('=== INTERACCIONES LIMPIADAS EXITOSAMENTE ===');
    } catch (e) {
      logError('Error al limpiar interacciones del usuario', e);
      rethrow;
    }
  }
}
