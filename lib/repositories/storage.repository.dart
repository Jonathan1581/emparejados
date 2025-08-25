import 'dart:io';

import 'package:emparejados/utils/logger.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Subir imagen de perfil
  Future<String> subirImagenPerfil(File imagen, String usuarioId) async {
    try {
      logInfo(
          'StorageRepository: Iniciando subida de imagen para usuario: $usuarioId');
      logInfo(
          'StorageRepository: Tamaño de imagen: ${imagen.lengthSync()} bytes');

      final ref = _storage.ref().child(
          'perfiles/$usuarioId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      logInfo(
          'StorageRepository: Referencia de storage creada: ${ref.fullPath}');

      final uploadTask = ref.putFile(imagen);
      logInfo('StorageRepository: Tarea de subida iniciada');

      final snapshot = await uploadTask;
      logInfo(
          'StorageRepository: Imagen subida exitosamente. Bytes transferidos: ${snapshot.bytesTransferred}');

      final downloadUrl = await snapshot.ref.getDownloadURL();
      logInfo(
          'StorageRepository: URL de descarga obtenida: ${downloadUrl.substring(0, 50)}...');

      return downloadUrl;
    } catch (e) {
      logError('Error al subir imagen de perfil', e);
      rethrow;
    }
  }

  // Subir múltiples imágenes de perfil
  Future<List<String>> subirImagenesPerfil(
      List<File> imagenes, String usuarioId) async {
    try {
      List<String> urls = [];
      for (int i = 0; i < imagenes.length; i++) {
        final ref = _storage.ref().child('perfiles/$usuarioId/imagen_$i.jpg');
        final uploadTask = ref.putFile(imagenes[i]);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        urls.add(downloadUrl);
      }
      return urls;
    } catch (e) {
      logError('Error al subir imágenes de perfil', e);
      rethrow;
    }
  }

  // Seleccionar imagen de la galería
  Future<File?> seleccionarImagenGaleria() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return imagen != null ? File(imagen.path) : null;
    } catch (e) {
      logError('Error al seleccionar imagen de galería', e);
      return null;
    }
  }

  // Tomar foto con la cámara
  Future<File?> tomarFotoCamara() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return imagen != null ? File(imagen.path) : null;
    } catch (e) {
      logError('Error al tomar foto con cámara', e);
      return null;
    }
  }

  // Eliminar imagen
  Future<void> eliminarImagen(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      logError('Error al eliminar imagen', e);
      rethrow;
    }
  }

  // Obtener URL de imagen
  Future<String> obtenerUrlImagen(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      logError('Error al obtener URL de imagen', e);
      rethrow;
    }
  }

  // Subir imagen de chat
  Future<String> subirImagenChat(File imagen, String matchId) async {
    try {
      final ref = _storage
          .ref()
          .child('chat/$matchId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = ref.putFile(imagen);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      logError('Error al subir imagen de chat', e);
      rethrow;
    }
  }

  // Comprimir imagen antes de subir
  Future<File> comprimirImagen(File imagen) async {
    try {
      // Aquí se podría implementar compresión de imagen
      // Por ahora retornamos la imagen original
      return imagen;
    } catch (e) {
      logError('Error al comprimir imagen', e);
      return imagen;
    }
  }

  // Validar tipo de archivo
  bool esImagenValida(File archivo) {
    final extension = archivo.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif'].contains(extension);
  }

  // Validar tamaño de archivo (máximo 10MB)
  bool esTamanioValido(File archivo) {
    const maxSize = 10 * 1024 * 1024; // 10MB
    return archivo.lengthSync() <= maxSize;
  }
}
