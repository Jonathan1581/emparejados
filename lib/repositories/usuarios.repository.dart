import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emparejados/models/usuario.model.dart';
import 'package:emparejados/utils/logger.dart';

class UsuariosRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuario por ID
  Future<Usuario?> obtenerUsuario(String id) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(id).get();
      if (doc.exists) {
        return Usuario.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logError('Error al obtener usuario', e);
      return null;
    }
  }

  // Obtener usuarios para emparejamiento (excluyendo al usuario actual)
  Stream<List<Usuario>> obtenerUsuariosParaEmparejar(
    String usuarioActualId,
    String generoInteres,
    List<String> usuariosVistos,
  ) {
    try {
      logInfo(
          '=== USUARIOS REPOSITORY: Obteniendo usuarios para emparejar ===');
      logInfo('Usuario actual ID: $usuarioActualId');
      logInfo('Género de interés: $generoInteres');
      logInfo('Usuarios vistos: ${usuariosVistos.length}');
      logInfo('IDs de usuarios vistos: $usuariosVistos');

      logInfo('Construyendo consulta Firestore...');
      logInfo('Collection: usuarios');
      logInfo('Where: genero = $generoInteres');
      logInfo('NOTA: Filtro de verificado eliminado');

      final stream = _firestore
          .collection('usuarios')
          .where('genero', isEqualTo: generoInteres)
          .snapshots()
          .map((snapshot) {
        logInfo('Snapshot recibido de Firestore');
        logInfo('Total documentos en snapshot: ${snapshot.docs.length}');

        if (snapshot.docs.isNotEmpty) {
          logInfo('Primer documento: ${snapshot.docs.first.id}');
          logInfo('Último documento: ${snapshot.docs.last.id}');
        }

        final usuariosFiltrados = snapshot.docs
            .where((doc) {
              final esUsuarioActual = doc.id != usuarioActualId;
              if (!esUsuarioActual) {
                logInfo('Excluyendo usuario actual: ${doc.id}');
              }
              return esUsuarioActual;
            })
            .where((doc) {
              final noHaSidoVisto = !usuariosVistos.contains(doc.id);
              if (!noHaSidoVisto) {
                logInfo('Excluyendo usuario ya visto: ${doc.id}');
              }
              return noHaSidoVisto;
            })
            .map(Usuario.fromFirestore)
            .toList();

        logInfo('Usuarios después de filtros: ${usuariosFiltrados.length}');

        if (usuariosFiltrados.isNotEmpty) {
          logInfo(
              'Primer usuario filtrado: ${usuariosFiltrados.first.nombre} (${usuariosFiltrados.first.genero})');
          logInfo(
              'Último usuario filtrado: ${usuariosFiltrados.last.nombre} (${usuariosFiltrados.last.genero})');
        }

        logInfo('=== FIN OBTENER USUARIOS PARA EMPAREJAR ===');
        return usuariosFiltrados;
      });

      logInfo('Stream creado exitosamente');
      return stream;
    } catch (e) {
      logError('Error al obtener usuarios para emparejar', e);
      logInfo('Retornando stream vacío debido al error');
      return Stream.value([]);
    }
  }

  // Actualizar usuario
  Future<void> actualizarUsuario(Usuario usuario) async {
    try {
      await _firestore
          .collection('usuarios')
          .doc(usuario.id)
          .update(usuario.toFirestore());
    } catch (e) {
      logError('Error al actualizar usuario', e);
      rethrow;
    }
  }

  // Eliminar usuario
  Future<void> eliminarUsuario(String id) async {
    try {
      await _firestore.collection('usuarios').doc(id).delete();
    } catch (e) {
      logError('Error al eliminar usuario', e);
      rethrow;
    }
  }

  // Buscar usuarios por intereses
  Future<List<Usuario>> buscarUsuariosPorIntereses(
    List<String> intereses,
    String usuarioActualId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('intereses', arrayContainsAny: intereses)
          .get();

      return querySnapshot.docs
          .where((doc) => doc.id != usuarioActualId)
          .map(Usuario.fromFirestore)
          .toList();
    } catch (e) {
      logError('Error al buscar usuarios por intereses', e);
      return [];
    }
  }

  // Obtener usuarios cercanos por ubicación
  Future<List<Usuario>> obtenerUsuariosCercanos(
    GeoPoint ubicacionUsuario,
    double radioKm,
    String usuarioActualId,
  ) async {
    try {
      // Nota: Firestore no soporta consultas geoespaciales nativas
      // Esta es una implementación básica que se puede mejorar
      final querySnapshot = await _firestore.collection('usuarios').get();

      final usuarios = querySnapshot.docs
          .where((doc) => doc.id != usuarioActualId)
          .map(Usuario.fromFirestore)
          .toList();

      // Filtrar por distancia (implementación básica)
      return usuarios.where((usuario) {
        final distancia =
            _calcularDistancia(ubicacionUsuario, usuario.ubicacion);
        return distancia <= radioKm;
      }).toList();
    } catch (e) {
      logError('Error al obtener usuarios cercanos', e);
      return [];
    }
  }

  // Calcular distancia entre dos puntos (fórmula de Haversine)
  double _calcularDistancia(GeoPoint punto1, GeoPoint punto2) {
    const double radioTierra = 6371; // km

    final lat1 = punto1.latitude * (pi / 180);
    final lat2 = punto2.latitude * (pi / 180);
    final deltaLat = (punto2.latitude - punto1.latitude) * (pi / 180);
    final deltaLon = (punto2.longitude - punto1.longitude) * (pi / 180);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radioTierra * c;
  }
}
