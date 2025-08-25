import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emparejados/models/usuario.model.dart';
import 'package:emparejados/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream del usuario actual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Registrar usuario con email y contraseña
  Future<UserCredential> registrarConEmail(
    String email,
    String password,
    Usuario usuario,
  ) async {
    try {
      logInfo('AuthRepository: Iniciando creación de usuario en Firebase Auth');

      // Primero crear el usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      logInfo(
          'AuthRepository: Usuario creado en Firebase Auth con UID: ${userCredential.user!.uid}');

      // Obtener el UID del usuario creado
      final String uid = userCredential.user!.uid;

      logInfo('AuthRepository: Creando documento de usuario en Firestore');

      // Crear el documento del usuario en Firestore con el UID correcto
      final usuarioConId = Usuario(
        id: uid,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        email: usuario.email,
        fechaNacimiento: usuario.fechaNacimiento,
        genero: usuario.genero,
        generoInteres: usuario.generoInteres,
        fotos: usuario.fotos,
        bio: usuario.bio,
        latitud: usuario.latitud,
        longitud: usuario.longitud,
        intereses: usuario.intereses,
        fechaCreacion: usuario.fechaCreacion,
      );

      logInfo('AuthRepository: Guardando usuario en Firestore');

      // Guardar en Firestore
      await _firestore
          .collection('usuarios')
          .doc(uid)
          .set(usuarioConId.toFirestore());

      logInfo('AuthRepository: Usuario guardado exitosamente en Firestore');
      return userCredential;
    } catch (e) {
      logError('Error al registrar usuario', e);
      rethrow;
    }
  }

  // Iniciar sesión con email y contraseña
  Future<UserCredential> iniciarSesion(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      logError('Error al iniciar sesión', e);
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    try {
      await _auth.signOut();
    } catch (e) {
      logError('Error al cerrar sesión', e);
      rethrow;
    }
  }

  // Obtener usuario actual desde Firestore
  Future<Usuario?> obtenerUsuarioActual() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final doc = await _firestore.collection('usuarios').doc(user.uid).get();

      if (doc.exists) {
        return Usuario.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logError('Error al obtener usuario actual', e);
      return null;
    }
  }

  // Actualizar perfil del usuario
  Future<void> actualizarPerfil(Usuario usuario) async {
    try {
      await _firestore
          .collection('usuarios')
          .doc(usuario.id)
          .update(usuario.toFirestore());
    } catch (e) {
      logError('Error al actualizar perfil', e);
      rethrow;
    }
  }

  // Restablecer contraseña
  Future<void> restablecerContrasena(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      logError('Error al restablecer contraseña', e);
      rethrow;
    }
  }
}
