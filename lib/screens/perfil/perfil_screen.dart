import 'package:cached_network_image/cached_network_image.dart';
import 'package:emparejados/models/usuario.model.dart';
import 'package:emparejados/providers/auth.provider.dart';
import 'package:emparejados/routes/router.dart';

import 'package:emparejados/screens/perfil/widgets/editar_perfil.widget.dart';
import 'package:emparejados/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  Usuario? _usuario;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfilUsuario();
  }

  Future<void> _cargarPerfilUsuario() async {
    try {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = true;
      });

      // Obtener el usuario actual desde el provider usando el patrón correcto
      final usuario = await ref.read(usuarioActualProvider.future);

      if (usuario != null) {
        if (mounted) {
          setState(() {
            _usuario = usuario;
            _isLoading = false;
          });
        }
        logInfo('Perfil de usuario cargado exitosamente');
      } else {
        logWarning('No se encontró usuario autenticado');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      logError('Error al cargar perfil de usuario', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B6B),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : _usuario == null
                ? _buildErrorState()
                : _buildPerfilCompleto(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar perfil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No se pudo cargar la información del usuario',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _cargarPerfilUsuario,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFF6B6B),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilCompleto() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con foto principal y botones
          Container(
            height: 300,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B6B),
            ),
            child: Stack(
              children: [
                // Foto principal de fondo
                if (_usuario!.fotos.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: _usuario!.fotos.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 300,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.error,
                        size: 80,
                        color: Colors.red,
                      ),
                    ),
                  )
                else
                  Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                // Overlay gradiente
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                // Botones de acción
                Positioned(
                  top: 0,
                  right: 0,
                  child: Row(
                    children: [
                      // Botón de editar perfil
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _editarPerfil,
                      ),
                      // Botón de configuración
                      IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          context.push('/configuracion');
                        },
                      ),
                    ],
                  ),
                ),
                // Información del usuario
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_usuario!.nombre} ${_usuario!.apellido}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_calcularEdad(_usuario!.fechaNacimiento)} años',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido del perfil
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio
                  if (_usuario!.bio.isNotEmpty) ...[
                    _buildSeccion(
                      titulo: 'Sobre mí',
                      icono: Icons.edit,
                      child: Text(
                        _usuario!.bio,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Intereses
                  if (_usuario!.intereses.isNotEmpty) ...[
                    _buildSeccion(
                      titulo: 'Intereses',
                      icono: Icons.interests,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _usuario!.intereses.map((interes) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              interes,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Información adicional
                  _buildSeccion(
                    titulo: 'Información',
                    icono: Icons.info,
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icono: Icons.person,
                          titulo: 'Género',
                          valor: _usuario!.genero,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icono: Icons.favorite,
                          titulo: 'Interesado en',
                          valor: _usuario!.generoInteres,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icono: Icons.calendar_today,
                          titulo: 'Fecha de nacimiento',
                          valor: _formatearFecha(_usuario!.fechaNacimiento),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icono: Icons.calendar_month,
                          titulo: 'Miembro desde',
                          valor: _formatearFecha(_usuario!.fechaCreacion),
                        ),
                        const SizedBox(height: 16),
                        // Botón de editar información
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _editarPerfil,
                            icon: const Icon(Icons.edit,
                                color: Color(0xFFFF6B6B)),
                            label: const Text(
                              'Editar Información',
                              style: TextStyle(
                                color: Color(0xFFFF6B6B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              side: const BorderSide(color: Color(0xFFFF6B6B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botón de cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cerrarSesion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required IconData icono,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icono,
              color: const Color(0xFFFF6B6B),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B6B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Row(
      children: [
        Icon(
          icono,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                valor,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _calcularEdad(DateTime fechaNacimiento) {
    final ahora = DateTime.now();
    int edad = ahora.year - fechaNacimiento.year;
    if (ahora.month < fechaNacimiento.month ||
        (ahora.month == fechaNacimiento.month &&
            ahora.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  void _editarPerfil() {
    if (_usuario != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => EditarPerfilWidget(
          usuario: _usuario!,
          onPerfilActualizado: _cargarPerfilUsuario,
        ),
      );
    }
  }

  Future<void> _cerrarSesion() async {
    try {
      logInfo('Cerrando sesión...');
      await ref.read(authProvider.notifier).cerrarSesion();
      logInfo('Sesión cerrada exitosamente');

      if (mounted) {
        // Navegar a la pantalla de login usando GoRouter
        context.go(AppRouter.login);
      }
    } catch (e) {
      logError('Error al cerrar sesión', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
