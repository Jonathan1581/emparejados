import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emparejados/utils/logger.dart';

class Match {
  final String id;
  final String usuario1Id;
  final String usuario2Id;
  final DateTime fechaMatch;
  final bool usuario1Liked;
  final bool usuario2Liked;
  final bool esMatch;
  final DateTime? fechaUltimoMensaje;
  final int mensajesNoLeidos;

  Match({
    required this.id,
    required this.usuario1Id,
    required this.usuario2Id,
    required this.fechaMatch,
    required this.usuario1Liked,
    required this.usuario2Liked,
    this.esMatch = false,
    this.fechaUltimoMensaje,
    this.mensajesNoLeidos = 0,
  });

  factory Match.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Agregar logs para debugging
    logInfo('DEBUG: Datos del documento: $data');

    // Función helper para convertir a bool de forma segura
    bool safeBool(value) {
      if (value is bool) {
        return value;
      }
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      if (value is int) {
        return value != 0;
      }
      return false;
    }

    // Función helper para convertir a int de forma segura
    int safeInt(value) {
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      if (value is double) {
        return value.toInt();
      }
      return 0;
    }

    return Match(
      id: doc.id,
      usuario1Id: data['usuario1Id']?.toString() ?? '',
      usuario2Id: data['usuario2Id']?.toString() ?? '',
      fechaMatch: data['fechaMatch'] is Timestamp
          ? (data['fechaMatch'] as Timestamp).toDate()
          : DateTime.now(),
      usuario1Liked: safeBool(data['usuario1Liked']),
      usuario2Liked: safeBool(data['usuario2Liked']),
      esMatch: safeBool(data['esMatch']),
      fechaUltimoMensaje: data['fechaUltimoMensaje'] is Timestamp
          ? (data['fechaUltimoMensaje'] as Timestamp).toDate()
          : null,
      mensajesNoLeidos: safeInt(data['mensajesNoLeidos']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'usuario1Id': usuario1Id,
      'usuario2Id': usuario2Id,
      'fechaMatch': Timestamp.fromDate(fechaMatch),
      'usuario1Liked': usuario1Liked,
      'usuario2Liked': usuario2Liked,
      'esMatch': esMatch,
      'fechaUltimoMensaje': fechaUltimoMensaje != null
          ? Timestamp.fromDate(fechaUltimoMensaje!)
          : null,
      'mensajesNoLeidos': mensajesNoLeidos,
    };
  }

  bool get esMatchCompleto => usuario1Liked && usuario2Liked;

  String get otroUsuarioId => usuario1Id;

  bool usuarioLiked(String usuarioId) {
    if (usuarioId == usuario1Id) {
      return usuario1Liked;
    }
    if (usuarioId == usuario2Id) {
      return usuario2Liked;
    }
    return false;
  }
}
