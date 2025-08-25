import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final DateTime fechaNacimiento;
  final String genero;
  final String generoInteres;
  final List<String> fotos;
  final String bio;
  final double latitud;
  final double longitud;
  final List<String> intereses;
  final DateTime fechaCreacion;
  final int edad;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.fechaNacimiento,
    required this.genero,
    required this.generoInteres,
    required this.fotos,
    required this.bio,
    required this.latitud,
    required this.longitud,
    required this.intereses,
    required this.fechaCreacion,
  }) : edad = DateTime.now().year - fechaNacimiento.year;

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Usuario(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
      email: data['email'] ?? '',
      fechaNacimiento: (data['fechaNacimiento'] as Timestamp).toDate(),
      genero: data['genero'] ?? '',
      generoInteres: data['generoInteres'] ?? '',
      fotos: List<String>.from(data['fotos'] ?? []),
      bio: data['bio'] ?? '',
      latitud: (data['latitud'] ?? 0.0).toDouble(),
      longitud: (data['longitud'] ?? 0.0).toDouble(),
      intereses: List<String>.from(data['intereses'] ?? []),
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'fechaNacimiento': Timestamp.fromDate(fechaNacimiento),
      'genero': genero,
      'generoInteres': generoInteres,
      'fotos': fotos,
      'bio': bio,
      'latitud': latitud,
      'longitud': longitud,
      'intereses': intereses,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }

  String get nombreCompleto => '$nombre $apellido';

  bool get tieneFotos => fotos.isNotEmpty;

  String? get fotoPrincipal => fotos.isNotEmpty ? fotos.first : null;

  // Getter para compatibilidad con código existente
  GeoPoint get ubicacion => GeoPoint(latitud, longitud);
}
