import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoInteraccion {
  like,
  dislike,
  superLike,
  favorito,
}

class InteraccionUsuario {
  final String id;
  final String usuarioActualId;
  final String usuarioObjetivoId;
  final TipoInteraccion tipo;
  final DateTime fechaInteraccion;
  final bool esReciproco; // Si ambos usuarios se gustaron
  final String? matchId; // Referencia al match si existe

  InteraccionUsuario({
    required this.id,
    required this.usuarioActualId,
    required this.usuarioObjetivoId,
    required this.tipo,
    required this.fechaInteraccion,
    this.esReciproco = false,
    this.matchId,
  });

  InteraccionUsuario copyWith({
    String? id,
    String? usuarioActualId,
    String? usuarioObjetivoId,
    TipoInteraccion? tipo,
    DateTime? fechaInteraccion,
    bool? esReciproco,
    String? matchId,
  }) {
    return InteraccionUsuario(
      id: id ?? this.id,
      usuarioActualId: usuarioActualId ?? this.usuarioActualId,
      usuarioObjetivoId: usuarioObjetivoId ?? this.usuarioObjetivoId,
      tipo: tipo ?? this.tipo,
      fechaInteraccion: fechaInteraccion ?? this.fechaInteraccion,
      esReciproco: esReciproco ?? this.esReciproco,
      matchId: matchId ?? this.matchId,
    );
  }

  factory InteraccionUsuario.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return InteraccionUsuario(
      id: doc.id,
      usuarioActualId: data['usuarioActualId'] ?? '',
      usuarioObjetivoId: data['usuarioObjetivoId'] ?? '',
      tipo: TipoInteraccion.values.firstWhere(
        (e) => e.name == (data['tipo'] ?? 'like'),
        orElse: () => TipoInteraccion.like,
      ),
      fechaInteraccion: (data['fechaInteraccion'] as Timestamp).toDate(),
      esReciproco: data['esReciproco'] ?? false,
      matchId: data['matchId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'usuarioActualId': usuarioActualId,
      'usuarioObjetivoId': usuarioObjetivoId,
      'tipo': tipo.name,
      'fechaInteraccion': Timestamp.fromDate(fechaInteraccion),
      'esReciproco': esReciproco,
      'matchId': matchId,
    };
  }

  // Crear ID compuesto para consultas eficientes
  static String crearIdCompuesto(String usuario1Id, String usuario2Id) {
    final ids = [usuario1Id, usuario2Id]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Verificar si es la misma interacción (mismos usuarios)
  bool esMismaInteraccion(InteraccionUsuario otra) {
    return (usuarioActualId == otra.usuarioActualId &&
            usuarioObjetivoId == otra.usuarioObjetivoId) ||
        (usuarioActualId == otra.usuarioObjetivoId &&
            usuarioObjetivoId == otra.usuarioActualId);
  }
}
