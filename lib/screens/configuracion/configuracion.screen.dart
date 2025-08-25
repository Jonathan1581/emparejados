import 'package:emparejados/providers/auth.provider.dart';
import 'package:emparejados/routes/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConfiguracionScreen extends ConsumerStatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  ConsumerState<ConfiguracionScreen> createState() =>
      _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends ConsumerState<ConfiguracionScreen> {
  // Filtros de búsqueda
  RangeValues _rangoEdad = const RangeValues(18, 50);
  double _distanciaMaxima = 50.0;
  final List<String> _interesesSeleccionados = [];

  // Configuración de notificaciones
  bool _notificacionesLikes = true;
  bool _notificacionesMatches = true;
  bool _notificacionesMensajes = true;
  bool _notificacionesPush = true;

  // Configuración de cuenta
  final bool _cuentaVerificada = false;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B6B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6B6B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtros de búsqueda
            _buildSeccionFiltros(),
            const SizedBox(height: 24),

            // Notificaciones
            _buildSeccionNotificaciones(),
            const SizedBox(height: 24),

            // Cuenta
            _buildSeccionCuenta(),
            const SizedBox(height: 24),

            // Acciones de cuenta
            _buildAccionesCuenta(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionFiltros() {
    return _buildSeccion(
      titulo: 'Filtros de Búsqueda',
      icono: Icons.filter_list,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rango de edad
          const Text(
            'Rango de edad',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 8),
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
            onChanged: (RangeValues values) {
              if (mounted) {
                setState(() {
                  _rangoEdad = values;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Distancia máxima
          const Text(
            'Distancia máxima',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _distanciaMaxima,
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: const Color(0xFFFF6B6B),
            inactiveColor: Colors.grey[300],
            label: '${_distanciaMaxima.round()} km',
            onChanged: (double value) {
              if (mounted) {
                setState(() {
                  _distanciaMaxima = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Intereses
          const Text(
            'Intereses preferidos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interesesDisponibles.map((interes) {
              final isSelected = _interesesSeleccionados.contains(interes);
              return GestureDetector(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      if (isSelected) {
                        _interesesSeleccionados.remove(interes);
                      } else {
                        if (_interesesSeleccionados.length < 5) {
                          _interesesSeleccionados.add(interes);
                        }
                      }
                    });
                  }
                },
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

  Widget _buildSeccionNotificaciones() {
    return _buildSeccion(
      titulo: 'Notificaciones',
      icono: Icons.notifications,
      child: Column(
        children: [
          _buildSwitchTile(
            titulo: 'Notificaciones push',
            subtitulo: 'Recibir notificaciones en tiempo real',
            valor: _notificacionesPush,
            onChanged: (value) {
              setState(() {
                _notificacionesPush = value;
              });
            },
          ),
          if (_notificacionesPush) ...[
            _buildSwitchTile(
              titulo: 'Nuevos likes',
              subtitulo: 'Cuando alguien te da like',
              valor: _notificacionesLikes,
              onChanged: (value) {
                setState(() {
                  _notificacionesLikes = value;
                });
              },
            ),
            _buildSwitchTile(
              titulo: 'Nuevos matches',
              subtitulo: 'Cuando haces match con alguien',
              valor: _notificacionesMatches,
              onChanged: (value) {
                setState(() {
                  _notificacionesMatches = value;
                });
              },
            ),
            _buildSwitchTile(
              titulo: 'Nuevos mensajes',
              subtitulo: 'Cuando recibes un mensaje',
              valor: _notificacionesMensajes,
              onChanged: (value) {
                setState(() {
                  _notificacionesMensajes = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionCuenta() {
    return _buildSeccion(
      titulo: 'Cuenta',
      icono: Icons.account_circle,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              _cuentaVerificada ? Icons.verified : Icons.verified_user_outlined,
              color: _cuentaVerificada ? Colors.blue : Colors.grey,
            ),
            title: Text(
              'Verificación de cuenta',
              style: TextStyle(
                color: _cuentaVerificada ? Colors.blue : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _cuentaVerificada
                  ? 'Tu cuenta está verificada'
                  : 'Verifica tu cuenta para mayor seguridad',
              style: TextStyle(
                color: _cuentaVerificada ? Colors.blue[700] : Colors.grey[600],
              ),
            ),
            trailing: _cuentaVerificada
                ? const Icon(Icons.check_circle, color: Colors.blue)
                : TextButton(
                    onPressed: () {
                      // TODO: Implementar verificación de cuenta
                    },
                    child: const Text('Verificar'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesCuenta() {
    return _buildSeccion(
      titulo: 'Acciones',
      icono: Icons.settings,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFFFF6B6B)),
            title: const Text(
              'Editar perfil',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Modificar información personal'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navegar a editar perfil
            },
          ),
          ListTile(
            leading: const Icon(Icons.security, color: Color(0xFFFF6B6B)),
            title: const Text(
              'Cambiar contraseña',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Actualizar tu contraseña'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implementar cambio de contraseña
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFFFF6B6B)),
            title: const Text(
              'Acerca de',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Información de la aplicación'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Mostrar información de la app
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Salir de la aplicación'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              try {
                await ref.read(authProvider.notifier).cerrarSesion();
                if (mounted) {
                  context.go(AppRouter.login);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cerrar sesión: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitulo,
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: valor,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFFFF6B6B),
      ),
    );
  }
}
