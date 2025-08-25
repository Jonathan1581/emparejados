import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emparejados/models/interaccion_usuario.model.dart';
import 'package:emparejados/models/usuario.model.dart';
import 'package:emparejados/repositories/interacciones.repository.dart';
import 'package:emparejados/repositories/usuarios.repository.dart';
import 'package:emparejados/utils/logger.dart';
import 'package:emparejados/widgets/usuario_card.widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class EmparejamientoScreen extends StatefulWidget {
  const EmparejamientoScreen({super.key});

  @override
  State<EmparejamientoScreen> createState() => _EmparejamientoScreenState();
}

class _EmparejamientoScreenState extends State<EmparejamientoScreen>
    with TickerProviderStateMixin {
  // Controller para el swiper
  final CardSwiperController _cardController = CardSwiperController();

  // Repositories
  late final InteraccionesRepository _interaccionesRepository;
  late final UsuariosRepository _usuariosRepository;

  // Estado local simplificado
  List<Usuario> _usuariosDisponibles = [];
  List<String> _usuariosVistos = [];
  bool _isLoading = false;
  String? _error;
  Usuario? _usuarioActual;

  // Variables para filtros
  RangeValues _rangoEdad = const RangeValues(18, 50);
  double _distanciaMaxima = 25.0;
  String? _generoFiltro;

  final List<String> _generos = [
    'Masculino',
    'Femenino',
    'No binario',
    'Prefiero no decir'
  ];

  @override
  void initState() {
    super.initState();
    _interaccionesRepository = InteraccionesRepository();
    _usuariosRepository = UsuariosRepository();

    // Establecer usuario actual cuando se inicia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _establecerUsuarioActual();
    });

    // Escuchar cambios en la autenticación de Firebase
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && _usuarioActual?.id != user.uid) {
        logInfo('Usuario de Firebase cambiado en initState, actualizando...');
        _establecerUsuarioActual();
      }
    });
  }

  Future<void> _establecerUsuarioActual() async {
    try {
      logInfo('=== ESTABLECIENDO USUARIO ACTUAL EN EMPAREJAMIENTO SCREEN ===');

      // Obtener el usuario actual directamente de Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        logInfo('Usuario de Firebase encontrado: ${firebaseUser.uid}');

        // Obtener datos del usuario desde Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _usuarioActual = Usuario.fromFirestore(userDoc);

          logInfo(
              'Usuario encontrado: ${_usuarioActual!.nombre} ${_usuarioActual!.apellido}');
          logInfo('Género: ${_usuarioActual!.genero}');
          logInfo('Género interés: ${_usuarioActual!.generoInteres}');
          logInfo(
              'Ubicación: ${_usuarioActual!.latitud}, ${_usuarioActual!.longitud}');
          logInfo('Usuario actual establecido localmente');

          // Cargar datos directamente
          await _cargarDatos();
        } else {
          logWarning('No se encontró documento del usuario en Firestore');
        }
      } else {
        logWarning('No hay usuario autenticado en Firebase');
      }

      logInfo('=== FIN ESTABLECER USUARIO ACTUAL ===');
    } catch (e) {
      logError('Error al establecer usuario actual', e);
    }
  }

  Future<void> _cargarDatos() async {
    if (_usuarioActual == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logInfo('=== CARGANDO DATOS ===');

      // Primero cargar interacciones, luego usuarios
      await _cargarInteracciones();
      await _cargarUsuariosDisponibles();

      logInfo('=== DATOS CARGADOS EXITOSAMENTE ===');
    } catch (e) {
      logError('Error al cargar datos', e);
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarInteracciones() async {
    logInfo('=== CARGANDO INTERACCIONES ===');

    if (_usuarioActual == null) {
      return;
    }

    try {
      final interaccionesStream = _interaccionesRepository
          .obtenerInteraccionesUsuario(_usuarioActual!.id);

      // Obtener solo la primera emisión del stream con timeout
      final interacciones = await interaccionesStream.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          logWarning('Timeout al cargar interacciones, retornando lista vacía');
          return <InteraccionUsuario>[];
        },
      );
      final usuariosVistos = interacciones
          .map((interaccion) => interaccion.usuarioObjetivoId)
          .toList();

      setState(() {
        _usuariosVistos = usuariosVistos;
      });

      logInfo('Interacciones cargadas: ${interacciones.length}');
      logInfo('Usuarios vistos: ${usuariosVistos.length}');
    } catch (e) {
      logError('Error al cargar interacciones', e);
      // En caso de error, establecer lista vacía
      setState(() {
        _usuariosVistos = [];
      });
    }
  }

  Future<void> _cargarUsuariosDisponibles() async {
    logInfo('=== CARGANDO USUARIOS DISPONIBLES ===');

    if (_usuarioActual == null) {
      logWarning('Usuario actual es null, no se pueden cargar usuarios');
      return;
    }

    logInfo('Usuario actual encontrado, iniciando carga...');
    logInfo('Género de interés: ${_usuarioActual!.generoInteres}');
    logInfo('Usuarios vistos: ${_usuariosVistos.length}');
    logInfo('IDs de usuarios vistos: $_usuariosVistos');

    try {
      logInfo('Llamando a obtenerUsuariosParaEmparejar...');

      // Agregar timeout para evitar que se quede colgado
      final usuarios = await _usuariosRepository
          .obtenerUsuariosParaEmparejar(
            _usuarioActual!.id,
            _usuarioActual!.generoInteres,
            _usuariosVistos,
          )
          .first
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          logWarning('Timeout al cargar usuarios, retornando lista vacía');
          return <Usuario>[];
        },
      );

      logInfo('Usuarios obtenidos del repository: ${usuarios.length}');

      if (usuarios.isNotEmpty) {
        logInfo(
            'Primer usuario: ${usuarios.first.nombre} ${usuarios.first.apellido} (${usuarios.first.genero})');
        logInfo(
            'Último usuario: ${usuarios.last.nombre} ${usuarios.last.apellido} (${usuarios.last.genero})');
      } else {
        logWarning('No se obtuvieron usuarios del repository');
      }

      setState(() {
        _usuariosDisponibles = usuarios;
      });

      logInfo('Estado actualizado con ${usuarios.length} usuarios disponibles');
    } catch (e) {
      logError('Error al cargar usuarios disponibles', e);
      setState(() {
        _error = e.toString();
        _usuariosDisponibles = []; // Establecer lista vacía en caso de error
      });
    }

    logInfo('=== FIN CARGAR USUARIOS DISPONIBLES ===');
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  // Función que se ejecuta cuando se swipe hacia la derecha (LIKE)
  bool _onSwipeRight(
      int previousIndex, int currentIndex, CardSwiperDirection direction) {
    if (previousIndex < _usuariosDisponibles.length) {
      final usuario = _usuariosDisponibles[previousIndex];
      logInfo('👍 SWIPE RIGHT (LIKE): ${usuario.nombre}');

      // Dar like directamente usando el repository
      _darLike(usuario.id);

      // Mostrar feedback visual
      _mostrarFeedback('¡Like enviado!', Colors.green, Icons.favorite);
    }

    return true; // Permite que la tarjeta se deslice
  }

  // Función que se ejecuta cuando se swipe hacia la izquierda (REJECT)
  bool _onSwipeLeft(
      int previousIndex, int currentIndex, CardSwiperDirection direction) {
    if (previousIndex < _usuariosDisponibles.length) {
      final usuario = _usuariosDisponibles[previousIndex];
      logInfo('👎 SWIPE LEFT (REJECT): ${usuario.nombre}');

      // Rechazar directamente usando el repository
      _rechazarUsuario(usuario.id);

      // Mostrar feedback visual
      _mostrarFeedback('Usuario rechazado', Colors.red, Icons.close);
    }

    return true; // Permite que la tarjeta se deslice
  }

  // Función que se ejecuta cuando se swipe hacia arriba (SUPER LIKE)
  bool _onSwipeUp(
      int previousIndex, int currentIndex, CardSwiperDirection direction) {
    if (previousIndex < _usuariosDisponibles.length) {
      final usuario = _usuariosDisponibles[previousIndex];
      logInfo('⭐ SWIPE UP (SUPER LIKE): ${usuario.nombre}');

      // Super like directamente usando el repository
      _superLike(usuario.id);

      // Mostrar feedback visual
      _mostrarFeedback('¡Super Like!', Colors.blue, Icons.star);
    }

    return true; // Permite que la tarjeta se deslice
  }

  // Mostrar feedback visual
  void _mostrarFeedback(String mensaje, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(mensaje),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Función general para manejar todos los swipes
  bool _onSwipe(
      int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    logInfo('=== SWIPE DETECTADO ===');
    logInfo('Dirección: ${direction.name}');
    logInfo('Previous index: $previousIndex');
    logInfo('Current index: $currentIndex');

    switch (direction) {
      case CardSwiperDirection.right:
        return _onSwipeRight(previousIndex, currentIndex ?? 0, direction);
      case CardSwiperDirection.left:
        return _onSwipeLeft(previousIndex, currentIndex ?? 0, direction);
      case CardSwiperDirection.top:
        return _onSwipeUp(previousIndex, currentIndex ?? 0, direction);
      case CardSwiperDirection.bottom:
        // Swipe hacia abajo - no hacer nada
        return false;
      default:
        return false;
    }
  }

  // Función para dar like programáticamente (botón)
  void _darLikeBoton() {
    logInfo('👍 BOTÓN LIKE PRESIONADO');
    _cardController.swipe(CardSwiperDirection.right);
  }

  // Función para rechazar programáticamente (botón)
  void _rechazarBoton() {
    logInfo('👎 BOTÓN REJECT PRESIONADO');
    _cardController.swipe(CardSwiperDirection.left);
  }

  // Función para super like programáticamente (botón)
  void _superLikeBoton() {
    logInfo('⭐ BOTÓN SUPER LIKE PRESIONADO');
    _cardController.swipe(CardSwiperDirection.top);
  }

  // Implementación directa de like
  Future<void> _darLike(String usuarioId) async {
    if (_usuarioActual == null) {
      return;
    }

    try {
      logInfo('=== DANDO LIKE ===');
      logInfo('Usuario objetivo ID: $usuarioId');

      // Crear interacción en Firestore
      final interaccion = InteraccionUsuario(
        id: '',
        usuarioActualId: _usuarioActual!.id,
        usuarioObjetivoId: usuarioId,
        tipo: TipoInteraccion.like,
        fechaInteraccion: DateTime.now(),
      );

      await _interaccionesRepository.registrarInteraccion(interaccion);
      logInfo('Interacción registrada en Firestore');

      // Actualizar estado local inmediatamente
      setState(() {
        _usuariosVistos.add(usuarioId);
        _usuariosDisponibles.removeWhere((usuario) => usuario.id == usuarioId);
      });

      logInfo('Estado local actualizado');

      // Recargar usuarios disponibles para mantener la lista actualizada
      await _cargarUsuariosDisponibles();

      // Verificar si quedan usuarios disponibles
      if (_usuariosDisponibles.isEmpty) {
        logInfo('No quedan usuarios disponibles después del like');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Has visto todos los usuarios disponibles!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      logInfo('=== LIKE COMPLETADO ===');
    } catch (e) {
      logError('Error al dar like', e);

      // Mostrar mensaje de error más amigable
      String mensajeError = 'Error al procesar el like';
      if (e.toString().contains('permission-denied')) {
        mensajeError = 'Error de permisos. Verifica tu autenticación.';
      } else if (e.toString().contains('unavailable')) {
        mensajeError = 'Servicio no disponible. Intenta nuevamente.';
      } else if (e.toString().contains('network')) {
        mensajeError = 'Error de conexión. Verifica tu internet.';
      }

      setState(() {
        _error = mensajeError;
      });

      // Mostrar SnackBar con el error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Implementación directa de rechazo
  Future<void> _rechazarUsuario(String usuarioId) async {
    if (_usuarioActual == null) {
      return;
    }

    try {
      logInfo('=== RECHAZANDO USUARIO ===');
      logInfo('Usuario objetivo ID: $usuarioId');

      // Crear interacción de dislike en Firestore
      final interaccion = InteraccionUsuario(
        id: '',
        usuarioActualId: _usuarioActual!.id,
        usuarioObjetivoId: usuarioId,
        tipo: TipoInteraccion.dislike,
        fechaInteraccion: DateTime.now(),
      );

      await _interaccionesRepository.registrarInteraccion(interaccion);
      logInfo('Interacción de dislike registrada en Firestore');

      // Actualizar estado local inmediatamente
      setState(() {
        _usuariosVistos.add(usuarioId);
        _usuariosDisponibles.removeWhere((usuario) => usuario.id == usuarioId);
      });

      logInfo('Estado local actualizado');

      // Recargar usuarios disponibles para mantener la lista actualizada
      await _cargarUsuariosDisponibles();

      // Verificar si quedan usuarios disponibles
      if (_usuariosDisponibles.isEmpty) {
        logInfo('No quedan usuarios disponibles después del rechazo');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Has visto todos los usuarios disponibles!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      logInfo('=== RECHAZO COMPLETADO ===');
    } catch (e) {
      logError('Error al rechazar usuario', e);

      // Mostrar mensaje de error más amigable
      String mensajeError = 'Error al procesar el rechazo';
      if (e.toString().contains('permission-denied')) {
        mensajeError = 'Error de permisos. Verifica tu autenticación.';
      } else if (e.toString().contains('unavailable')) {
        mensajeError = 'Servicio no disponible. Intenta nuevamente.';
      } else if (e.toString().contains('network')) {
        mensajeError = 'Error de conexión. Verifica tu internet.';
      }

      setState(() {
        _error = mensajeError;
      });

      // Mostrar SnackBar con el error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Implementación directa de super like
  Future<void> _superLike(String usuarioId) async {
    if (_usuarioActual == null) {
      return;
    }

    try {
      logInfo('=== DANDO SUPER LIKE ===');
      logInfo('Usuario objetivo ID: $usuarioId');

      // Crear interacción de super like en Firestore
      final interaccion = InteraccionUsuario(
        id: '',
        usuarioActualId: _usuarioActual!.id,
        usuarioObjetivoId: usuarioId,
        tipo: TipoInteraccion.superLike,
        fechaInteraccion: DateTime.now(),
      );

      await _interaccionesRepository.registrarInteraccion(interaccion);
      logInfo('Interacción de super like registrada en Firestore');

      // Actualizar estado local inmediatamente
      setState(() {
        _usuariosVistos.add(usuarioId);
        _usuariosDisponibles.removeWhere((usuario) => usuario.id == usuarioId);
      });

      logInfo('Estado local actualizado');

      // Recargar usuarios disponibles para mantener la lista actualizada
      await _cargarUsuariosDisponibles();

      // Verificar si quedan usuarios disponibles
      if (_usuariosDisponibles.isEmpty) {
        logInfo('No quedan usuarios disponibles después del super like');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Has visto todos los usuarios disponibles!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      logInfo('=== SUPER LIKE COMPLETADO ===');
    } catch (e) {
      logError('Error al dar super like', e);

      // Mostrar mensaje de error más amigable
      String mensajeError = 'Error al procesar el super like';
      if (e.toString().contains('permission-denied')) {
        mensajeError = 'Error de permisos. Verifica tu autenticación.';
      } else if (e.toString().contains('unavailable')) {
        mensajeError = 'Servicio no disponible. Intenta nuevamente.';
      } else if (e.toString().contains('network')) {
        mensajeError = 'Error de conexión. Verifica tu internet.';
      }

      setState(() {
        _error = mensajeError;
      });

      // Mostrar SnackBar con el error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height,
        minHeight: MediaQuery.of(context).size.height,
      ),
      builder: (context) => _buildFiltrosModal(),
    );
  }

  Widget _buildFiltrosModal() {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B6B),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Filtros de Búsqueda',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _limpiarFiltros,
                        tooltip: 'Limpiar filtros',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Personaliza tu búsqueda de pareja ideal',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Contenido de filtros
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rango de edad
                    _buildSeccionFiltro(
                      titulo: 'Rango de Edad',
                      icono: Icons.calendar_today,
                      child: Column(
                        children: [
                          RangeSlider(
                            values: _rangoEdad,
                            min: 18,
                            max: 80,
                            divisions: 62,
                            activeColor: const Color(0xFFFF6B6B),
                            inactiveColor: Colors.grey[300],
                            labels: RangeLabels(
                              '${_rangoEdad.start.round()} años',
                              '${_rangoEdad.end.round()} años',
                            ),
                            onChanged: (values) {
                              if (mounted) {
                                setState(() {
                                  _rangoEdad = values;
                                });
                              }
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_rangoEdad.start.round()} años'),
                              Text('${_rangoEdad.end.round()} años'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Distancia máxima
                    _buildSeccionFiltro(
                      titulo: 'Distancia Máxima',
                      icono: Icons.location_on,
                      child: Column(
                        children: [
                          Slider(
                            value: _distanciaMaxima,
                            min: 1,
                            max: 100,
                            divisions: 99,
                            activeColor: const Color(0xFFFF6B6B),
                            inactiveColor: Colors.grey[300],
                            label: '${_distanciaMaxima.round()} km',
                            onChanged: (value) {
                              if (mounted) {
                                setState(() {
                                  _distanciaMaxima = value;
                                });
                              }
                            },
                          ),
                          Text('${_distanciaMaxima.round()} kilómetros'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Género específico (opcional)
                    _buildSeccionFiltro(
                      titulo: 'Género Específico (Opcional)',
                      icono: Icons.person_outline,
                      child: DropdownButtonFormField<String>(
                        initialValue: _generoFiltro,
                        decoration: InputDecoration(
                          hintText: 'Cualquier género',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            child: Text('Cualquier género'),
                          ),
                          ..._generos.map((genero) => DropdownMenuItem(
                                value: genero,
                                child: Text(genero),
                              )),
                        ],
                        onChanged: (value) {
                          if (mounted) {
                            setState(() {
                              _generoFiltro = value;
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(
                        height: 100), // Espacio para los botones fijos
                  ],
                ),
              ),
            ),

            // Botones de acción fijos en la parte inferior
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _limpiarFiltros,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFFF6B6B)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Limpiar Filtros',
                        style: TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _aplicarFiltros,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Aplicar Filtros',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionFiltro({
    required String titulo,
    required IconData icono,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: const Color(0xFFFF6B6B)),
            const SizedBox(width: 12),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _rangoEdad = const RangeValues(18, 50);
      _distanciaMaxima = 25.0;
      _generoFiltro = null;
    });
  }

  void _limpiarError() {
    setState(() {
      _error = null;
    });
  }

  Future<void> _limpiarInteraccionesYRecargar() async {
    if (_usuarioActual == null) {
      return;
    }

    try {
      logInfo('=== LIMPIANDO INTERACCIONES Y RECARGANDO ===');

      // Mostrar confirmación
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limpiar Historial'),
          content: const Text(
              '¿Estás seguro de que quieres limpiar todo tu historial de likes/dislikes? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Limpiar'),
            ),
          ],
        ),
      );

      if (confirmar != true) {
        return;
      }

      // Limpiar interacciones del usuario actual
      await _interaccionesRepository
          .limpiarInteraccionesUsuario(_usuarioActual!.id);

      // Limpiar estado local
      setState(() {
        _usuariosVistos.clear();
        _error = null;
      });

      // Recargar datos
      await _cargarDatos();

      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Historial limpiado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      logInfo('=== INTERACCIONES LIMPIADAS Y DATOS RECARGADOS ===');
    } catch (e) {
      logError('Error al limpiar interacciones', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al limpiar historial: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _aplicarFiltros() async {
    try {
      logInfo('=== APLICANDO FILTROS ===');
      logInfo(
          'Rango de edad: ${_rangoEdad.start.round()} - ${_rangoEdad.end.round()} años');
      logInfo('Distancia máxima: ${_distanciaMaxima.round()} km');
      logInfo('Género filtro: $_generoFiltro');

      // Cerrar el modal
      Navigator.pop(context);
      logInfo('Modal cerrado');

      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aplicando filtros...'),
          backgroundColor: Colors.blue,
        ),
      );
      logInfo('SnackBar de carga mostrado');

      // TODO: Implementar filtros en el repository
      logInfo('Filtros aplicados, recargando usuarios...');

      // Recargar usuarios con los nuevos filtros
      await _cargarDatos();

      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filtros aplicados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        logInfo('SnackBar de confirmación mostrado');
      }

      logInfo('=== FILTROS APLICADOS EXITOSAMENTE ===');
    } catch (e) {
      logError('Error al aplicar filtros', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aplicar filtros: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en la autenticación de Firebase
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && _usuarioActual?.id != user.uid) {
        logInfo('Usuario de Firebase cambiado, actualizando...');
        _establecerUsuarioActual();
      }
    });

    logInfo('=== EMPAREJAMIENTO SCREEN: Build method ===');
    logInfo('Estado de carga: $_isLoading');
    logInfo('Usuarios disponibles: ${_usuariosDisponibles.length}');
    logInfo('Usuario actual: ${_usuarioActual?.nombre ?? "null"}');
    logInfo('Error: ${_error ?? "ninguno"}');
    logInfo(
        'Firebase Auth usuario: ${FirebaseAuth.instance.currentUser?.uid ?? "null"}');

    if (_usuariosDisponibles.isNotEmpty) {
      logInfo(
          'Primer usuario disponible: ${_usuariosDisponibles.first.nombre}');
      logInfo('Último usuario disponible: ${_usuariosDisponibles.last.nombre}');
    } else {
      logWarning('No hay usuarios disponibles en el estado');
    }

    logInfo('=== FIN BUILD METHOD ===');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Emparejados',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B6B),
                fontSize: 18,
              ),
            ),
            if (_usuariosDisponibles.isNotEmpty)
              Text(
                '${_usuariosDisponibles.length} usuarios disponibles',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF6B6B)),
            onPressed: () {
              logInfo('=== REFRESH MANUAL DESDE APP BAR ===');
              _cargarDatos();
            },
            tooltip: 'Refrescar',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFFFF6B6B)),
            onPressed: _mostrarFiltros,
          ),
        ],
      ),
      body: Column(
        children: [
          // Área de tarjetas con swipe
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
                    ),
                  )
                : _error != null
                    ? _buildErrorWidget()
                    : _usuariosDisponibles.isEmpty
                        ? _buildNoHayUsuarios()
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: CardSwiper(
                              controller: _cardController,
                              cardsCount: _usuariosDisponibles.length,
                              onSwipe: _onSwipe,
                              // Configuración de escala - tarjetas más grandes
                              scale: 0.98,
                              // Número de tarjetas mostradas (máximo 2, mínimo 1)
                              numberOfCardsDisplayed:
                                  _usuariosDisponibles.length > 1 ? 2 : 1,
                              // Configuración de espaciado para tarjetas más grandes
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 4),
                              // Offset de la tarjeta de fondo para mejor efecto visual
                              backCardOffset: const Offset(0, 12),
                              // Función builder para cada tarjeta
                              cardBuilder: (context,
                                  index,
                                  horizontalThresholdPercentage,
                                  verticalThresholdPercentage) {
                                // Verificar que el índice sea válido
                                if (index >= _usuariosDisponibles.length) {
                                  return const SizedBox.shrink();
                                }

                                final usuario = _usuariosDisponibles[index];

                                return Stack(
                                  children: [
                                    // Tarjeta principal
                                    UsuarioCard(
                                      usuario: usuario,
                                      onLike: () => _darLike(usuario.id),
                                      onReject: () =>
                                          _rechazarUsuario(usuario.id),
                                      onSuperLike: () => _superLike(usuario.id),
                                    ),

                                    // Indicadores de swipe en tiempo real
                                    // Indicador de LIKE (derecha)
                                    if (horizontalThresholdPercentage > 0.1)
                                      Positioned(
                                        right: 20,
                                        top: 50,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.green
                                                .withValues(alpha: 0.8),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.green, width: 2),
                                          ),
                                          child: const Text(
                                            'LIKE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Indicador de REJECT (izquierda)
                                    if (horizontalThresholdPercentage < -0.1)
                                      Positioned(
                                        left: 20,
                                        top: 50,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.red
                                                .withValues(alpha: 0.8),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.red, width: 2),
                                          ),
                                          child: const Text(
                                            'PASS',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Indicador de SUPER LIKE (arriba)
                                    if (verticalThresholdPercentage > 0.1)
                                      Positioned(
                                        top: 20,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue
                                                  .withValues(alpha: 0.8),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: Colors.blue, width: 2),
                                            ),
                                            child: const Text(
                                              '⭐ SUPER LIKE',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
          ),

          // Botones de acción
          if (_usuariosDisponibles.isNotEmpty) _buildBotonesAccion(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar usuarios',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Error desconocido',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  logInfo('=== BOTÓN REINTENTAR PRESIONADO ===');
                  _limpiarError();
                  _cargarDatos();
                  logInfo('Reintentando carga de datos...');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Reintentar'),
              ),
              ElevatedButton(
                onPressed: () {
                  logInfo('=== BOTÓN REFRESCAR AUTH PRESIONADO ===');
                  _establecerUsuarioActual();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Refrescar Auth'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoHayUsuarios() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay más usuarios disponibles',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta ajustar tus filtros o espera un poco',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  logInfo('=== BOTÓN REFRESCAR PRESIONADO ===');
                  _cargarDatos();
                  logInfo('_cargarDatos() llamado');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Refrescar'),
              ),
              ElevatedButton(
                onPressed: () {
                  logInfo('=== BOTÓN LIMPIAR INTERACCIONES PRESIONADO ===');
                  _limpiarInteraccionesYRecargar();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Limpiar Historial'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botón de rechazar
          _buildBotonAccion(
            icon: Icons.close,
            color: Colors.red,
            onPressed: _rechazarBoton,
            size: 60,
            tooltip: 'Rechazar (desliza izquierda)',
          ),

          // Botón de super like
          _buildBotonAccion(
            icon: Icons.star,
            color: Colors.blue,
            onPressed: _superLikeBoton,
            size: 50,
            tooltip: 'Super Like (desliza arriba)',
          ),

          // Botón de like
          _buildBotonAccion(
            icon: Icons.favorite,
            color: const Color(0xFFFF6B6B),
            onPressed: _darLikeBoton,
            size: 60,
            tooltip: 'Me gusta (desliza derecha)',
          ),
        ],
      ),
    );
  }

  Widget _buildBotonAccion({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required double size,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: color, size: size * 0.4),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
