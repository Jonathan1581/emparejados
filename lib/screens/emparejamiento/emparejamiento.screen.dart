import 'package:emparejados/providers/auth.provider.dart';
import 'package:emparejados/providers/emparejamiento.provider.dart';
import 'package:emparejados/utils/logger.dart';
import 'package:emparejados/widgets/usuario_card.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmparejamientoScreen extends ConsumerStatefulWidget {
  const EmparejamientoScreen({super.key});

  @override
  ConsumerState<EmparejamientoScreen> createState() =>
      _EmparejamientoScreenState();
}

class _EmparejamientoScreenState extends ConsumerState<EmparejamientoScreen>
    with TickerProviderStateMixin {
  // Controller para el swiper
  final CardSwiperController _cardController = CardSwiperController();

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
    // Establecer usuario actual cuando se inicia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _establecerUsuarioActual();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Establecer usuario actual cuando se cargan las dependencias
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _establecerUsuarioActual();
    });
  }

  void _establecerUsuarioActual() {
    try {
      logInfo('=== ESTABLECIENDO USUARIO ACTUAL EN EMPAREJAMIENTO SCREEN ===');

      // Obtener el usuario actual del provider de auth
      final authState = ref.read(authProvider);
      logInfo(
          'Estado de auth: ${authState.isLoading ? "cargando" : "completado"}');
      logInfo('Usuario: ${authState.usuario?.nombre ?? "null"}');

      if (authState.usuario != null) {
        logInfo(
            'Usuario encontrado: ${authState.usuario!.nombre} ${authState.usuario!.apellido}');
        logInfo('Género: ${authState.usuario!.genero}');
        logInfo('Género interés: ${authState.usuario!.generoInteres}');
        logInfo(
            'Ubicación: ${authState.usuario!.latitud}, ${authState.usuario!.longitud}');

        // Establecer usuario en el provider de emparejamiento
        ref
            .read(emparejamientoProvider.notifier)
            .establecerUsuarioActual(authState.usuario!);
        logInfo('Usuario establecido en emparejamiento provider');
      } else {
        logWarning('No se pudo obtener usuario del auth provider');
        logInfo('Auth state usuario: ${authState.usuario?.nombre ?? "null"}');
      }

      logInfo('=== FIN ESTABLECER USUARIO ACTUAL ===');
    } catch (e) {
      logError('Error al establecer usuario actual', e);
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  // Función que se ejecuta cuando se swipe hacia la derecha (LIKE)
  bool _onSwipeRight(
      int previousIndex, int currentIndex, CardSwiperDirection direction) {
    final emparejamientoState = ref.read(emparejamientoProvider);

    if (previousIndex < emparejamientoState.usuariosDisponibles.length) {
      final usuario = emparejamientoState.usuariosDisponibles[previousIndex];
      logInfo('👍 SWIPE RIGHT (LIKE): ${usuario.nombre}');

      // Dar like usando el provider
      ref.read(emparejamientoProvider.notifier).darLike(usuario.id);

      // Mostrar feedback visual
      _mostrarFeedback('¡Like enviado!', Colors.green, Icons.favorite);
    }

    return true; // Permite que la tarjeta se deslice
  }

  // Función que se ejecuta cuando se swipe hacia la izquierda (REJECT)
  bool _onSwipeLeft(
      int previousIndex, int currentIndex, CardSwiperDirection direction) {
    final emparejamientoState = ref.read(emparejamientoProvider);

    if (previousIndex < emparejamientoState.usuariosDisponibles.length) {
      final usuario = emparejamientoState.usuariosDisponibles[previousIndex];
      logInfo('👎 SWIPE LEFT (REJECT): ${usuario.nombre}');

      // Rechazar usando el provider
      ref.read(emparejamientoProvider.notifier).rechazarUsuario(usuario.id);

      // Mostrar feedback visual
      _mostrarFeedback('Usuario rechazado', Colors.red, Icons.close);
    }

    return true; // Permite que la tarjeta se deslice
  }

  // Función que se ejecuta cuando se swipe hacia arriba (SUPER LIKE)
  bool _onSwipeUp(
      int previousIndex, int currentIndex, CardSwiperDirection direction) {
    final emparejamientoState = ref.read(emparejamientoProvider);

    if (previousIndex < emparejamientoState.usuariosDisponibles.length) {
      final usuario = emparejamientoState.usuariosDisponibles[previousIndex];
      logInfo('⭐ SWIPE UP (SUPER LIKE): ${usuario.nombre}');

      // Super like usando el provider
      ref.read(emparejamientoProvider.notifier).superLike(usuario.id);

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
  void _darLike() {
    logInfo('👍 BOTÓN LIKE PRESIONADO');
    _cardController.swipe(CardSwiperDirection.right);
  }

  // Función para rechazar programáticamente (botón)
  void _rechazar() {
    logInfo('👎 BOTÓN REJECT PRESIONADO');
    _cardController.swipe(CardSwiperDirection.left);
  }

  // Función para super like programáticamente (botón)
  void _superLike() {
    logInfo('⭐ BOTÓN SUPER LIKE PRESIONADO');
    _cardController.swipe(CardSwiperDirection.top);
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

      // Aplicar filtros usando el provider
      final emparejamientoNotifier = ref.read(emparejamientoProvider.notifier);
      logInfo('Notifier del provider obtenido');

      // Aplicar filtro de edad si está configurado
      if (_rangoEdad.start > 18 || _rangoEdad.end < 80) {
        // TODO: Implementar filtro por edad en el provider
        logInfo(
            'Filtro de edad: ${_rangoEdad.start.round()} - ${_rangoEdad.end.round()} años');
      }

      // Aplicar filtro de distancia
      if (_distanciaMaxima < 100) {
        // TODO: Implementar filtro por distancia en el provider
        logInfo('Filtro de distancia: ${_distanciaMaxima.round()} km');
      }

      // Aplicar filtro de género específico
      if (_generoFiltro != null) {
        // TODO: Implementar filtro por género específico en el provider
        logInfo('Filtro de género: $_generoFiltro');
      }

      // Refrescar usuarios con los nuevos filtros
      logInfo('Llamando a refrescarUsuarios()...');
      await emparejamientoNotifier.refrescarUsuarios();
      logInfo('refrescarUsuarios() completado');

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
    final emparejamientoState = ref.watch(emparejamientoProvider);
    final authState = ref.watch(authProvider);

    // Escuchar cambios en el usuario autenticado
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.usuario != next.usuario && next.usuario != null) {
        logInfo(
            'Usuario cambiado en auth provider, estableciendo en emparejamiento...');
        _establecerUsuarioActual();
      }
    });

    logInfo('=== EMPAREJAMIENTO SCREEN: Build method ===');
    logInfo('Estado de carga: ${emparejamientoState.isLoading}');
    logInfo(
        'Usuarios disponibles: ${emparejamientoState.usuariosDisponibles.length}');
    logInfo(
        'Usuario actual: ${emparejamientoState.usuarioActual?.nombre ?? "null"}');
    logInfo('Error: ${emparejamientoState.error ?? "ninguno"}');
    logInfo('Auth state usuario: ${authState.usuario?.nombre ?? "null"}');

    if (emparejamientoState.usuariosDisponibles.isNotEmpty) {
      logInfo(
          'Primer usuario disponible: ${emparejamientoState.usuariosDisponibles.first.nombre}');
      logInfo(
          'Último usuario disponible: ${emparejamientoState.usuariosDisponibles.last.nombre}');
    } else {
      logWarning('No hay usuarios disponibles en el estado');
    }

    logInfo('=== FIN BUILD METHOD ===');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Emparejados',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B6B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
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
            child: emparejamientoState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
                    ),
                  )
                : emparejamientoState.usuariosDisponibles.isEmpty
                    ? _buildNoHayUsuarios()
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: CardSwiper(
                          controller: _cardController,
                          cardsCount:
                              emparejamientoState.usuariosDisponibles.length,
                          onSwipe: _onSwipe,
                          // Configuración de escala - tarjetas más grandes
                          scale: 0.98,
                          // Número de tarjetas mostradas (máximo 2, mínimo 1)
                          numberOfCardsDisplayed:
                              emparejamientoState.usuariosDisponibles.length > 1
                                  ? 2
                                  : 1,
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
                            if (index >=
                                emparejamientoState
                                    .usuariosDisponibles.length) {
                              return const SizedBox.shrink();
                            }

                            final usuario =
                                emparejamientoState.usuariosDisponibles[index];

                            return Stack(
                              children: [
                                // Tarjeta principal
                                UsuarioCard(
                                  usuario: usuario,
                                  onLike: _darLike,
                                  onReject: _rechazar,
                                  onSuperLike: _superLike,
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
                                        color: Colors.green.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(20),
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
                                        color: Colors.red.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(20),
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
                                          color: Colors.blue.withValues(alpha: 0.8),
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
          if (emparejamientoState.usuariosDisponibles.isNotEmpty)
            _buildBotonesAccion(),
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
          ElevatedButton(
            onPressed: () {
              logInfo('=== BOTÓN REFRESCAR PRESIONADO ===');
              final estadoActual = ref.read(emparejamientoProvider);
              logInfo(
                  'Estado actual: ${estadoActual.usuariosDisponibles.length} usuarios disponibles');
              logInfo(
                  'Usuario actual: ${estadoActual.usuarioActual?.nombre ?? "null"}');

              ref.read(emparejamientoProvider.notifier).refrescarUsuarios();

              logInfo('refrescarUsuarios() llamado');
              logInfo('=== FIN BOTÓN REFRESCAR ===');
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
            onPressed: _rechazar,
            size: 60,
            tooltip: 'Rechazar (desliza izquierda)',
          ),

          // Botón de super like
          _buildBotonAccion(
            icon: Icons.star,
            color: Colors.blue,
            onPressed: _superLike,
            size: 50,
            tooltip: 'Super Like (desliza arriba)',
          ),

          // Botón de like
          _buildBotonAccion(
            icon: Icons.favorite,
            color: const Color(0xFFFF6B6B),
            onPressed: _darLike,
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
