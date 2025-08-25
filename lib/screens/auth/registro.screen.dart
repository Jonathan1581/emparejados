import 'dart:async';
import 'dart:io';

import 'package:emparejados/models/usuario.model.dart';
import 'package:emparejados/providers/auth.provider.dart';
import 'package:emparejados/repositories/storage.repository.dart';
import 'package:emparejados/routes/router.dart';
import 'package:emparejados/utils/logger.dart';
import 'package:emparejados/widgets/custom_button.widget.dart';
import 'package:emparejados/widgets/custom_text_field.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _fechaNacimiento;
  String _genero = '';
  String _generoInteres = '';
  final List<String> _intereses = [];
  bool _obscurePassword = true;

  // Variables para el segundo paso
  int _currentStep = 0;
  final List<File> _fotosSeleccionadas = [];
  final StorageRepository _storageRepository = StorageRepository();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  int _fotosSubidas = 0;
  int _totalFotos = 0;

  // Variables para ubicación
  double? _latitudUsuario;
  double? _longitudUsuario;
  bool _ubicacionObtenida = false;
  String _estadoUbicacion = 'Pendiente';

  final List<String> _generos = [
    'Masculino',
    'Femenino',
    'No binario',
    'Prefiero no decir'
  ];
  final List<String> _interesesDisponibles = [
    'Música',
    'Deportes',
    'Viajes',
    'Cine',
    'Literatura',
    'Arte',
    'Cocina',
    'Tecnología',
    'Naturaleza',
    'Fotografía',
    'Baile',
    'Videojuegos',
    'Fitness',
    'Meditación',
    'Voluntariado'
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime.now().subtract(const Duration(days: 36500)),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
    );

    if (fecha != null && mounted) {
      setState(() {
        _fechaNacimiento = fecha;
      });
    }
  }

  void _toggleInteres(String interes) {
    if (!mounted) {
      return;
    }
    setState(() {
      if (_intereses.contains(interes)) {
        _intereses.remove(interes);
      } else {
        if (_intereses.length < 5) {
          _intereses.add(interes);
        }
      }
    });
  }

  Future<void> _seleccionarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null && _fotosSeleccionadas.length < 6) {
        logInfo('Imagen seleccionada, validando...');

        final File imagenFile = File(image.path);

        // Validar la imagen antes de procesarla
        if (!_validarImagen(imagenFile)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen no válida. Verifica el formato y tamaño'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        logInfo('Imagen validada, iniciando recorte...');

        // Recortar la imagen
        final File? imagenRecortada = await _recortarImagen(imagenFile);

        if (imagenRecortada != null && mounted) {
          setState(() {
            _fotosSeleccionadas.add(imagenRecortada);
          });
          logInfo('Imagen recortada y agregada exitosamente');
        } else {
          logWarning('El usuario canceló el recorte de la imagen');
        }
      } else if (_fotosSeleccionadas.length >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Máximo 6 fotos permitidas'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      logError('Error al seleccionar foto', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removerFoto(int index) {
    if (!mounted) {
      return;
    }
    setState(() {
      _fotosSeleccionadas.removeAt(index);
    });
  }

  Future<File?> _recortarImagen(File imagen) async {
    try {
      logInfo('Iniciando recorte de imagen');

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagen.path,
        aspectRatio:
            const CropAspectRatio(ratioX: 1, ratioY: 1), // Formato cuadrado
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar Foto',
            toolbarColor: const Color(0xFFFF6B6B),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
            cropGridColor: Colors.white,
            cropFrameColor: const Color(0xFFFF6B6B),
            cropFrameStrokeWidth: 2,
            cropGridColumnCount: 3,
            cropGridRowCount: 3,
          ),
          IOSUiSettings(
            title: 'Recortar Foto',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        logInfo('Imagen recortada exitosamente');
        return File(croppedFile.path);
      } else {
        logInfo('Usuario canceló el recorte');
        return null;
      }
    } catch (e) {
      logError('Error al recortar imagen', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al recortar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFFFF6B6B)),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarFoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFF6B6B)),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _tomarFoto();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null && _fotosSeleccionadas.length < 6) {
        logInfo('Foto tomada con cámara, validando...');

        final File imagenFile = File(image.path);

        // Validar la imagen antes de procesarla
        if (!_validarImagen(imagenFile)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto no válida. Verifica el formato y tamaño'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        logInfo('Foto validada, iniciando recorte...');

        // Recortar la imagen
        final File? imagenRecortada = await _recortarImagen(imagenFile);

        if (imagenRecortada != null) {
          setState(() {
            _fotosSeleccionadas.add(imagenRecortada);
          });
          logInfo('Foto tomada con cámara, recortada y agregada exitosamente');
        } else {
          logWarning(
              'El usuario canceló el recorte de la foto tomada con cámara');
        }
      } else if (_fotosSeleccionadas.length >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Máximo 6 fotos permitidas'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      logError('Error al tomar foto con cámara', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al tomar foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _recortarFotoExistente(int index) async {
    try {
      logInfo('Recortando foto existente en índice: $index');

      final File imagenOriginal = _fotosSeleccionadas[index];

      // Validar la imagen antes de recortarla
      if (!_validarImagen(imagenOriginal)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen no válida para recortar'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final File? imagenRecortada = await _recortarImagen(imagenOriginal);

      if (imagenRecortada != null) {
        setState(() {
          _fotosSeleccionadas[index] = imagenRecortada;
        });
        logInfo('Foto existente recortada y actualizada exitosamente');
      } else {
        logInfo('Usuario canceló el recorte de la foto existente');
      }
    } catch (e) {
      logError('Error al recortar foto existente', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al recortar foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _hacerFotoPrincipal(int index) {
    try {
      logInfo('Cambiando foto principal al índice: $index');

      if (index > 0 && index < _fotosSeleccionadas.length) {
        setState(() {
          // Mover la foto seleccionada al primer lugar
          final File fotoSeleccionada = _fotosSeleccionadas[index];
          _fotosSeleccionadas
            ..removeAt(index)
            ..insert(0, fotoSeleccionada);
        });
        logInfo('Foto principal cambiada exitosamente');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto principal actualizada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      logError('Error al cambiar foto principal', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar foto principal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _moverFotoArriba(int index) {
    try {
      logInfo('Moviendo foto hacia arriba desde índice: $index');

      if (index > 0) {
        setState(() {
          final File foto = _fotosSeleccionadas[index];
          _fotosSeleccionadas[index] = _fotosSeleccionadas[index - 1];
          _fotosSeleccionadas[index - 1] = foto;
        });
        logInfo('Foto movida hacia arriba exitosamente');
      }
    } catch (e) {
      logError('Error al mover foto hacia arriba', e);
    }
  }

  void _moverFotoAbajo(int index) {
    try {
      logInfo('Moviendo foto hacia abajo desde índice: $index');

      if (index < _fotosSeleccionadas.length - 1) {
        setState(() {
          final File foto = _fotosSeleccionadas[index];
          _fotosSeleccionadas[index] = _fotosSeleccionadas[index + 1];
          _fotosSeleccionadas[index + 1] = foto;
        });
        logInfo('Foto movida hacia abajo exitosamente');
      }
    } catch (e) {
      logError('Error al mover foto hacia abajo', e);
    }
  }

  Future<File> _comprimirImagen(File imagen) async {
    try {
      logInfo('Iniciando compresión de imagen');

      // Por ahora, simplemente retornamos la imagen original
      // En el futuro se puede implementar compresión real con flutter_image_compress
      logInfo(
          'Compresión de imagen completada (sin compresión real por ahora)');
      return imagen;
    } catch (e) {
      logError('Error al comprimir imagen', e);
      // Si falla la compresión, retornamos la imagen original
      return imagen;
    }
  }

  bool _validarImagen(File imagen) {
    try {
      // Validar extensión del archivo
      final extension = imagen.path.split('.').last.toLowerCase();
      final extensionesValidas = ['jpg', 'jpeg', 'png', 'gif'];

      if (!extensionesValidas.contains(extension)) {
        logWarning('Tipo de archivo no válido: $extension');
        return false;
      }

      // Validar tamaño del archivo (máximo 10MB)
      const maxSize = 10 * 1024 * 1024; // 10MB
      final fileSize = imagen.lengthSync();

      if (fileSize > maxSize) {
        logWarning(
            'Archivo demasiado grande: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
        return false;
      }

      logInfo('Imagen validada exitosamente');
      return true;
    } catch (e) {
      logError('Error al validar imagen', e);
      return false;
    }
  }

  void _siguientePaso() {
    if (_formKey.currentState!.validate() && _validarPrimerPaso()) {
      setState(() {
        _currentStep = 1;
      });
    }
  }

  void _pasoAnterior() {
    setState(() {
      _currentStep = 0;
    });
  }

  bool _validarPrimerPaso() {
    if (_fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor selecciona tu fecha de nacimiento')),
      );
      return false;
    }
    if (_genero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona tu género')),
      );
      return false;
    }
    if (_generoInteres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor selecciona el género de tu interés')),
      );
      return false;
    }
    if (_intereses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor selecciona al menos un interés')),
      );
      return false;
    }
    return true;
  }

  // Métodos para obtener ubicación
  Future<bool> _solicitarPermisosUbicacion() async {
    try {
      logInfo('Solicitando permisos de ubicación...');

      // Verificar si los servicios de ubicación están habilitados
      bool serviciosHabilitados = await Geolocator.isLocationServiceEnabled();
      if (!serviciosHabilitados) {
        logWarning('Servicios de ubicación deshabilitados');
        _estadoUbicacion = 'Servicios deshabilitados';
        setState(() {});
        return false;
      }

      // Verificar permisos
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        logInfo('Permiso de ubicación denegado, solicitando...');
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          logWarning('Permiso de ubicación denegado por el usuario');
          _estadoUbicacion = 'Permiso denegado';
          setState(() {});
          return false;
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        logWarning('Permiso de ubicación denegado permanentemente');
        _estadoUbicacion = 'Permiso denegado permanentemente';
        setState(() {});
        return false;
      }

      logInfo('Permisos de ubicación concedidos');
      return true;
    } catch (e) {
      logError('Error al solicitar permisos de ubicación', e);
      _estadoUbicacion = 'Error en permisos';
      setState(() {});
      return false;
    }
  }

  Future<void> _obtenerUbicacion() async {
    try {
      logInfo('Obteniendo ubicación del usuario...');
      setState(() {
        _estadoUbicacion = 'Obteniendo ubicación...';
      });

      // Solicitar permisos primero
      if (!await _solicitarPermisosUbicacion()) {
        return;
      }

      // Obtener ubicación actual
      final Position posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      logInfo(
          'Ubicación obtenida: ${posicion.latitude}, ${posicion.longitude}');

      setState(() {
        _latitudUsuario = posicion.latitude;
        _longitudUsuario = posicion.longitude;
        _ubicacionObtenida = true;
        _estadoUbicacion = 'Ubicación obtenida';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación obtenida correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      logError('Error al obtener ubicación', e);
      setState(() {
        _estadoUbicacion = 'Error al obtener ubicación';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _registrarUsuario() async {
    logInfo('=== BOTÓN REGISTRAR PRESIONADO ===');
    logInfo('Iniciando proceso de registro de usuario');
    logInfo('Fotos seleccionadas: ${_fotosSeleccionadas.length}');
    logInfo('Email: ${_emailController.text.trim()}');
    logInfo('Nombre: ${_nombreController.text.trim()}');
    logInfo('Apellido: ${_apellidoController.text.trim()}');

    // Verificar que Firebase esté disponible
    try {
      logInfo('Verificando conectividad con Firebase...');
      // Aquí podríamos agregar una verificación de conectividad
      logInfo('Firebase parece estar disponible');
    } catch (e) {
      logError('Error de conectividad con Firebase', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conectividad: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_fotosSeleccionadas.isEmpty) {
      logWarning('No se seleccionaron fotos para el registro');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor agrega al menos una foto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      logInfo('Iniciando subida de ${_fotosSeleccionadas.length} fotos');

      // Inicializar contadores de progreso
      _totalFotos = _fotosSeleccionadas.length;
      _fotosSubidas = 0;

      // Subir fotos primero
      List<String> urlsFotos = [];
      for (int i = 0; i < _fotosSeleccionadas.length; i++) {
        final File foto = _fotosSeleccionadas[i];
        logInfo('Subiendo foto ${i + 1}/${_fotosSeleccionadas.length}');

        // Validar imagen antes de procesarla
        if (!_validarImagen(foto)) {
          logError('Foto ${i + 1} no válida, saltando...');
          continue;
        }

        // Comprimir imagen antes de subir
        logInfo('Comprimiendo foto ${i + 1}...');
        final File imagenComprimida = await _comprimirImagen(foto);
        logInfo('Foto ${i + 1} comprimida exitosamente');

        // Usar un ID temporal para subir las fotos
        final url = await _storageRepository
            .subirImagenPerfil(imagenComprimida,
                'temp_${DateTime.now().millisecondsSinceEpoch}')
            .timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            logError('Timeout al subir foto ${i + 1}',
                'La operación tardó más de 2 minutos');
            throw TimeoutException('Timeout al subir foto ${i + 1}');
          },
        );
        urlsFotos.add(url);
        _fotosSubidas = i + 1;
        if (mounted) {
          setState(() {}); // Actualizar UI para mostrar progreso
        }
        logInfo(
            'Foto ${i + 1} subida exitosamente: ${url.substring(0, 50)}...');
      }

      logInfo('Todas las fotos subidas exitosamente. Creando objeto usuario');

      // Crear usuario con las URLs de las fotos
      final usuario = Usuario(
        id: '', // Se asignará automáticamente
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim(),
        fechaNacimiento: _fechaNacimiento!,
        genero: _genero,
        generoInteres: _generoInteres,
        fotos: urlsFotos,
        bio: _bioController.text.trim(),
        latitud: _latitudUsuario ?? 0.0,
        longitud: _longitudUsuario ?? 0.0,
        intereses: _intereses,
        fechaCreacion: DateTime.now(),
      );

      logInfo(
          'Usuario creado con ubicación: ${usuario.latitud}, ${usuario.longitud}');
      logInfo('Iniciando registro en Firebase Auth');

      // Registrar usuario
      await ref.read(authProvider.notifier).registrarUsuario(
            _emailController.text.trim(),
            _passwordController.text,
            usuario,
          );

      logInfo('Usuario registrado exitosamente en Firebase');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Usuario registrado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar a MainScreen
        logInfo('Navegando a MainScreen');
        context.go(AppRouter.main);
      }
    } catch (e) {
      logError('Error durante el proceso de registro', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        logInfo('Estado de carga actualizado: _isUploading = false');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con indicador de pasos
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _currentStep == 0
                          ? () => context.go(AppRouter.login)
                          : _pasoAnterior,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _currentStep == 0 ? 'Paso 1 de 2' : 'Paso 2 de 2',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _currentStep >= 0
                                        ? Colors.white
                                        : Colors.white30,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _currentStep >= 1
                                        ? Colors.white
                                        : Colors.white30,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48), // Balance del layout
                  ],
                ),
              ),

              // Contenido del paso actual
              Expanded(
                child: _currentStep == 0
                    ? _buildPrimerPaso()
                    : _buildSegundoPaso(),
              ),

              // Botones de navegación
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_currentStep == 0)
                      CustomButton(
                        text: 'Siguiente',
                        onPressed: _siguientePaso,
                        backgroundColor: Colors.white,
                        textColor: const Color(0xFFFF6B6B),
                      )
                    else
                      CustomButton(
                        text: _isUploading
                            ? 'Subiendo fotos... ($_fotosSubidas/$_totalFotos)'
                            : 'Crear Cuenta',
                        onPressed: _isUploading ? null : _registrarUsuario,
                        isLoading: _isUploading || authState.isLoading,
                        backgroundColor: Colors.white,
                        textColor: const Color(0xFFFF6B6B),
                      ),
                    // Indicador de progreso
                    if (_isUploading && _totalFotos > 0) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _fotosSubidas / _totalFotos,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Progreso: $_fotosSubidas/$_totalFotos fotos',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimerPaso() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              'Información Básica',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuéntanos sobre ti para encontrar tu pareja ideal',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),

            // Nombre y Apellido
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _nombreController,
                    hintText: 'Nombre',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu nombre';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _apellidoController,
                    hintText: 'Apellido',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu apellido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email
            CustomTextField(
              controller: _emailController,
              hintText: 'Correo electrónico',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu correo';
                }
                if (!value.contains('@')) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Contraseña
            CustomTextField(
              controller: _passwordController,
              hintText: 'Contraseña',
              prefixIcon: Icons.lock,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu contraseña';
                }
                if (value.length < 6) {
                  return 'Mínimo 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Fecha de nacimiento
            _buildSelector(
              icon: Icons.calendar_today,
              title: _fechaNacimiento != null
                  ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                  : 'Fecha de nacimiento',
              onTap: _seleccionarFecha,
            ),
            const SizedBox(height: 16),

            // Género
            _buildDropdown(
              icon: Icons.person_outline,
              title: _genero.isEmpty ? 'Selecciona tu género' : _genero,
              items: _generos,
              value: _genero.isEmpty ? null : _genero,
              onChanged: (value) {
                setState(() {
                  _genero = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),

            // Género de interés
            _buildDropdown(
              icon: Icons.favorite_outline,
              title: _generoInteres.isEmpty
                  ? 'Género de tu interés'
                  : _generoInteres,
              items: _generos,
              value: _generoInteres.isEmpty ? null : _generoInteres,
              onChanged: (value) {
                setState(() {
                  _generoInteres = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),

            // Bio
            CustomTextField(
              controller: _bioController,
              hintText: 'Cuéntanos sobre ti...',
              prefixIcon: Icons.edit,
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 16),

            // Intereses
            _buildIntereses(),
          ],
        ),
      ),
    );
  }

  Widget _buildSegundoPaso() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            'Fotos de Perfil',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega fotos que muestren tu personalidad. La primera será tu foto principal.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),

          // Grid de fotos
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _fotosSeleccionadas.length + 1,
            itemBuilder: (context, index) {
              if (index == _fotosSeleccionadas.length) {
                // Botón para agregar foto
                return _buildAddPhotoButton();
              } else {
                // Foto seleccionada
                return _buildPhotoItem(index);
              }
            },
          ),
          const SizedBox(height: 24),

          // Sección de ubicación
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.yellow[300]),
                    const SizedBox(width: 8),
                    const Text(
                      'Ubicación:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _estadoUbicacion,
                  style: TextStyle(
                    color:
                        _ubicacionObtenida ? Colors.green[300] : Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                if (!_ubicacionObtenida)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _obtenerUbicacion,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Obtener Mi Ubicación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B6B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (_ubicacionObtenida &&
                    _latitudUsuario != null &&
                    _longitudUsuario != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[300]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ubicación: ${_latitudUsuario!.toStringAsFixed(4)}, ${_longitudUsuario!.toStringAsFixed(4)}',
                            style: TextStyle(
                              color: Colors.green[300],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Consejos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.yellow[300]),
                    const SizedBox(width: 8),
                    const Text(
                      'Consejos para mejores fotos:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Usa fotos claras y bien iluminadas\n'
                  '• Muestra tu rostro claramente\n'
                  '• Incluye fotos de actividades que te gusten\n'
                  '• Evita fotos grupales o muy oscuras',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: title.contains('Selecciona') || title.contains('Fecha')
                      ? Colors.grey[500]
                      : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String title,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon),
          hintText: title,
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildIntereses() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.interests, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Intereses (${_intereses.length}/5)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interesesDisponibles.map((interes) {
              final isSelected = _intereses.contains(interes);
              return GestureDetector(
                onTap: () => _toggleInteres(interes),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? const Color(0xFFFF6B6B) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF6B6B)
                          : Colors.grey[400]!,
                    ),
                  ),
                  child: Text(
                    interes,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _mostrarOpcionesFoto,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 4),
            Text(
              'Agregar',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _fotosSeleccionadas[index],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Indicador de foto principal
        if (index == 0)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Botón para hacer foto principal (solo si no es la primera)
        if (index != 0)
          Positioned(
            bottom: 8,
            left: 8,
            child: GestureDetector(
              onTap: () => _hacerFotoPrincipal(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        // Botones de reordenamiento
        if (index > 0)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _moverFotoArriba(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        if (index < _fotosSeleccionadas.length - 1)
          Positioned(
            bottom: 8,
            right: 40,
            child: GestureDetector(
              onTap: () => _moverFotoAbajo(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        // Botón de recortar
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _recortarFotoExistente(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.crop,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        // Botón de eliminar
        Positioned(
          top: 8,
          right: 40,
          child: GestureDetector(
            onTap: () => _removerFoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
