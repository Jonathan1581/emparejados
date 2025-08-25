import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emparejados/models/mensaje.model.dart';
import 'package:emparejados/utils/logger.dart';

class MensajesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Enviar mensaje
  Future<void> enviarMensaje(Mensaje mensaje) async {
    try {
      logInfo('=== ENVIANDO MENSAJE ===');
      logInfo('Match ID: ${mensaje.matchId}');
      logInfo('Remitente ID: ${mensaje.remitenteId}');
      logInfo('Contenido: ${mensaje.contenido}');
      logInfo('Tipo: ${mensaje.tipo}');

      // Crear el mensaje en Firestore
      final docRef =
          await _firestore.collection('mensajes').add(mensaje.toFirestore());
      logInfo('Mensaje creado con ID: ${docRef.id}');

      // Actualizar último mensaje en el match
      logInfo('Actualizando match con último mensaje...');
      await _firestore.collection('matches').doc(mensaje.matchId).update({
        'fechaUltimoMensaje': FieldValue.serverTimestamp(),
        'mensajesNoLeidos': FieldValue.increment(1),
      });
      logInfo('Match actualizado exitosamente');

      logInfo('=== MENSAJE ENVIADO EXITOSAMENTE ===');
    } catch (e) {
      logError('Error al enviar mensaje', e);
      rethrow;
    }
  }

  // Obtener mensajes de un match
  Stream<List<Mensaje>> obtenerMensajes(String matchId) {
    try {
      logInfo('=== OBTENIENDO MENSAJES ===');
      logInfo('Match ID: $matchId');

      return _firestore
          .collection('mensajes')
          .where('matchId', isEqualTo: matchId)
          .limit(
              100) // Limitar a 100 mensajes para evitar problemas de rendimiento
          .snapshots()
          .map((snapshot) {
        logInfo('Snapshot recibido: ${snapshot.docs.length} mensajes');

        final mensajes = snapshot.docs
            .map((doc) {
              try {
                return Mensaje.fromFirestore(doc);
              } catch (e) {
                logError('Error al parsear mensaje ${doc.id}', e);
                return null;
              }
            })
            .whereType<Mensaje>()
            .toList()

        // Ordenar localmente por fecha de envío
        ..sort((a, b) => a.fechaEnvio.compareTo(b.fechaEnvio));

        logInfo(
            'Mensajes parseados y ordenados localmente: ${mensajes.length}');
        return mensajes;
      });
    } catch (e) {
      logError('Error al obtener mensajes', e);
      return Stream.value([]);
    }
  }

  // Obtener mensajes de un match (método alternativo sin ordenamiento)
  Stream<List<Mensaje>> obtenerMensajesSinOrdenar(String matchId) {
    try {
      logInfo('=== OBTENIENDO MENSAJES SIN ORDENAR ===');
      logInfo('Match ID: $matchId');

      return _firestore
          .collection('mensajes')
          .where('matchId', isEqualTo: matchId)
          .limit(100)
          .snapshots()
          .map((snapshot) {
        logInfo('Snapshot recibido: ${snapshot.docs.length} mensajes');

        final mensajes = snapshot.docs
            .map((doc) {
              try {
                return Mensaje.fromFirestore(doc);
              } catch (e) {
                logError('Error al parsear mensaje ${doc.id}', e);
                return null;
              }
            })
            .whereType<Mensaje>()
            .toList()

          // Ordenar localmente si es necesario
          ..sort((a, b) => a.fechaEnvio.compareTo(b.fechaEnvio));

        logInfo(
            'Mensajes parseados y ordenados localmente: ${mensajes.length}');
        return mensajes;
      });
    } catch (e) {
      logError('Error al obtener mensajes sin ordenar', e);
      return Stream.value([]);
    }
  }

  // Marcar mensajes como leídos
  Future<void> marcarMensajesComoLeidos(
      String matchId, String usuarioId) async {
    try {
      logInfo('=== MARCANDO MENSAJES COMO LEÍDOS ===');
      logInfo('Match ID: $matchId');
      logInfo('Usuario ID: $usuarioId');

      // Obtener todos los mensajes del match (más simple, sin filtros complejos)
      final mensajesSnapshot = await _firestore
          .collection('mensajes')
          .where('matchId', isEqualTo: matchId)
          .get();

      logInfo('Total mensajes en match: ${mensajesSnapshot.docs.length}');

      if (mensajesSnapshot.docs.isEmpty) {
        logInfo('No hay mensajes para marcar como leídos');
        return;
      }

      // Filtrar localmente los mensajes no leídos del otro usuario
      final mensajesNoLeidos = mensajesSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['remitenteId'] != usuarioId && data['leido'] == false;
      }).toList();

      logInfo('Mensajes no leídos encontrados: ${mensajesNoLeidos.length}');

      if (mensajesNoLeidos.isEmpty) {
        logInfo('No hay mensajes para marcar como leídos');
        return;
      }

      // Usar batch para actualizar todos los mensajes
      final batch = _firestore.batch();
      for (final doc in mensajesNoLeidos) {
        logInfo('Marcando mensaje ${doc.id} como leído');
        batch.update(doc.reference, {'leido': true});
      }

      // Ejecutar batch
      await batch.commit();
      logInfo('Batch de mensajes ejecutado exitosamente');

      // Resetear contador de mensajes no leídos en el match
      logInfo('Reseteando contador de mensajes no leídos...');
      await _firestore
          .collection('matches')
          .doc(matchId)
          .update({'mensajesNoLeidos': 0});

      logInfo('Contador de mensajes no leídos reseteado a 0');
      logInfo('=== MENSAJES MARCADOS COMO LEÍDOS EXITOSAMENTE ===');
    } catch (e) {
      logError('Error al marcar mensajes como leídos', e);
      rethrow;
    }
  }

  // Eliminar mensaje
  Future<void> eliminarMensaje(String mensajeId) async {
    try {
      await _firestore.collection('mensajes').doc(mensajeId).delete();
    } catch (e) {
      logError('Error al eliminar mensaje', e);
      rethrow;
    }
  }

  // Obtener mensajes no leídos de un usuario
  Stream<int> obtenerMensajesNoLeidos(String usuarioId) {
    try {
      return _firestore
          .collection('matches')
          .where('usuario2Id', isEqualTo: usuarioId)
          .snapshots()
          .map((snapshot) {
        int total = 0;
        for (final doc in snapshot.docs) {
          total += (doc.data()['mensajesNoLeidos'] ?? 0) as int;
        }
        return total;
      });
    } catch (e) {
      logError('Error al obtener mensajes no leídos', e);
      return Stream.value(0);
    }
  }

  // Buscar mensajes por contenido
  Future<List<Mensaje>> buscarMensajes(String matchId, String query) async {
    try {
      final mensajesSnapshot = await _firestore
          .collection('mensajes')
          .where('matchId', isEqualTo: matchId)
          .where('contenido', isGreaterThanOrEqualTo: query)
          .where('contenido', isLessThan: '$query\uf8ff')
          .orderBy('contenido')
          .orderBy('fechaEnvio', descending: true)
          .get();

      return mensajesSnapshot.docs.map(Mensaje.fromFirestore).toList();
    } catch (e) {
      logError('Error al buscar mensajes', e);
      return [];
    }
  }

  // Obtener estadísticas de mensajes
  Future<Map<String, int>> obtenerEstadisticasMensajes(String usuarioId) async {
    try {
      final mensajesEnviadosSnapshot = await _firestore
          .collection('mensajes')
          .where('remitenteId', isEqualTo: usuarioId)
          .get();

      final mensajesRecibidosSnapshot = await _firestore
          .collection('mensajes')
          .where('remitenteId', isNotEqualTo: usuarioId)
          .get();

      int mensajesEnviados = mensajesEnviadosSnapshot.docs.length;
      int mensajesRecibidos = mensajesRecibidosSnapshot.docs.length;
      int mensajesNoLeidos = 0;

      // Contar mensajes no leídos
      for (final doc in mensajesRecibidosSnapshot.docs) {
        if (doc.data()['leido'] == false) {
          mensajesNoLeidos++;
        }
      }

      return {
        'enviados': mensajesEnviados,
        'recibidos': mensajesRecibidos,
        'noLeidos': mensajesNoLeidos,
      };
    } catch (e) {
      logError('Error al obtener estadísticas de mensajes', e);
      return {
        'enviados': 0,
        'recibidos': 0,
        'noLeidos': 0,
      };
    }
  }
}
