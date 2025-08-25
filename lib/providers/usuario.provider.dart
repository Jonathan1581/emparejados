import 'package:emparejados/models/usuario.model.dart';
import 'package:emparejados/repositories/usuarios.repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final usuarioActualProvider = FutureProvider<Usuario?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return null;
  }

  final usuariosRepository = UsuariosRepository();
  return await usuariosRepository.obtenerUsuario(user.uid);
});

final usuarioIdProvider = Provider<String?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return user?.uid;
});

final usuarioStreamProvider = StreamProvider<Usuario?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(null);
  }

  final usuariosRepository = UsuariosRepository();
  return usuariosRepository.obtenerUsuario(user.uid).asStream();
});
