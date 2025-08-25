import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emparejados/utils/logger.dart';

class Mensaje {
  final String id;
  final String matchId;
  final String remitenteId;
  final String contenido;
  final DateTime fechaEnvio;
  final bool leido;
  final String? tipo; // texto, imagen, audio, etc.

  Mensaje({
    required this.id,
    required this.matchId,
    required this.remitenteId,
    required this.contenido,
    required this.fechaEnvio,
    this.leido = false,
    this.tipo = 'texto',
  });

  factory Mensaje.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      logInfo('DEBUG: Parseando mensaje: ${doc.id} - $data');

      return Mensaje(
        id: doc.id,
        matchId: data['matchId']?.toString() ?? '',
        remitenteId: data['remitenteId']?.toString() ?? '',
        contenido: data['contenido']?.toString() ?? '',
        fechaEnvio: data['fechaEnvio'] is Timestamp
            ? (data['fechaEnvio'] as Timestamp).toDate()
            : DateTime.now(),
        leido: data['leido'] == true,
        tipo: data['tipo']?.toString() ?? 'texto',
      );
    } catch (e) {
      logError('Error al parsear mensaje desde Firestore', e);
      logInfo('Documento problemático: ${doc.data()}');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'remitenteId': remitenteId,
      'contenido': contenido,
      'fechaEnvio': Timestamp.fromDate(fechaEnvio),
      'leido': leido,
      'tipo': tipo,
    };
  }

  bool get esMio => false; // Se implementará en el provider

  String get horaFormateada {
    final now = DateTime.now();
    final diferencia = now.difference(fechaEnvio);

    if (diferencia.inDays > 0) {
      return '${diferencia.inDays}d';
    } else if (diferencia.inHours > 0) {
      return '${diferencia.inHours}h';
    } else if (diferencia.inMinutes > 0) {
      return '${diferencia.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  @override
  String toString() {
    return 'Mensaje{id: $id, contenido: $contenido, remitenteId: $remitenteId, fecha: $fechaEnvio, leido: $leido}';
  }
}
