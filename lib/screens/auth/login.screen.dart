import 'package:emparejados/providers/auth.provider.dart';
import 'package:emparejados/routes/router.dart';
import 'package:emparejados/utils/logger.dart';
import 'package:emparejados/widgets/custom_button.widget.dart';
import 'package:emparejados/widgets/custom_text_field.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _guardarSesion = false;
  bool _verificandoCredenciales = true; // Nuevo estado

  @override
  void initState() {
    super.initState();
    _verificarCredencialesGuardadas();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verificarCredencialesGuardadas() async {
    try {
      logInfo('Verificando credenciales guardadas...');

      final credenciales =
          await ref.read(authProvider.notifier).obtenerCredencialesGuardadas();

      if (credenciales != null) {
        logInfo('Credenciales encontradas, configurando campos...');

        if (mounted) {
          setState(() {
            _emailController.text = credenciales['email']!;
            _passwordController.text = credenciales['password']!;
            _guardarSesion = true;
          });
        }

        // Verificar si las credenciales siguen siendo válidas
        logInfo('Verificando validez de credenciales guardadas...');
        try {
          await _iniciarSesion();
          logInfo('Login automático exitoso con credenciales guardadas');
        } catch (e) {
          logWarning('Credenciales guardadas expiradas o inválidas: $e');
          // Limpiar credenciales inválidas
          await ref.read(authProvider.notifier).limpiarCredencialesGuardadas();
          if (mounted) {
            setState(() {
              _guardarSesion = false;
            });
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Sesión expirada. Por favor, inicia sesión nuevamente.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        logInfo('No hay credenciales guardadas');
      }
    } catch (e) {
      logError('Error al verificar credenciales guardadas', e);
    } finally {
      // Marcar que la verificación ha terminado
      if (mounted) {
        setState(() {
          _verificandoCredenciales = false;
        });
      }
    }
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      logInfo('Iniciando sesión con email: ${_emailController.text.trim()}');

      await ref.read(authProvider.notifier).iniciarSesion(
            _emailController.text.trim(),
            _passwordController.text,
            guardarSesion: _guardarSesion,
          );

      logInfo('Sesión iniciada exitosamente');

      // Navegar a MainScreen después del login exitoso
      if (mounted) {
        context.go(AppRouter.main);
      }
    } catch (e) {
      logError('Error al iniciar sesión', e);

      if (mounted) {
        String mensajeError = 'Error al iniciar sesión';

        // Traducir errores de Firebase a mensajes más claros
        if (e.toString().contains('invalid-credential')) {
          mensajeError = 'Email o contraseña incorrectos';
        } else if (e.toString().contains('user-not-found')) {
          mensajeError = 'Usuario no encontrado';
        } else if (e.toString().contains('wrong-password')) {
          mensajeError = 'Contraseña incorrecta';
        } else if (e.toString().contains('too-many-requests')) {
          mensajeError = 'Demasiados intentos. Intenta más tarde';
        } else if (e.toString().contains('network-request-failed')) {
          mensajeError = 'Error de conexión. Verifica tu internet';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Mostrar pantalla de carga mientras se verifican credenciales
    if (_verificandoCredenciales) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 24),
                Text(
                  'Verificando sesión...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo y título
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 60,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Emparejados',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'Encuentra tu pareja ideal',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Campo de email
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Correo electrónico',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu correo';
                        }
                        if (!value.contains('@')) {
                          return 'Por favor ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo de contraseña
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Contraseña',
                      prefixIcon: Icons.lock,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
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
                          return 'Por favor ingresa tu contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Checkbox para guardar sesión
                    Row(
                      children: [
                        Checkbox(
                          value: _guardarSesion,
                          onChanged: (value) {
                            setState(() {
                              _guardarSesion = value ?? false;
                            });
                          },
                          activeColor: Colors.white,
                          checkColor: const Color(0xFFFF6B6B),
                        ),
                        const Text(
                          'Guardar sesión',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (_guardarSesion)
                          TextButton(
                            onPressed: () async {
                              await ref
                                  .read(authProvider.notifier)
                                  .limpiarCredencialesGuardadas();
                              setState(() {
                                _guardarSesion = false;
                                _emailController.clear();
                                _passwordController.clear();
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Credenciales guardadas eliminadas'),
                                    backgroundColor: Colors.blue,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Limpiar',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón de iniciar sesión
                    CustomButton(
                      text: 'Iniciar Sesión',
                      onPressed: authState.isLoading ? null : _iniciarSesion,
                      isLoading: authState.isLoading,
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(height: 16),

                    // Enlaces adicionales
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            // TODO: Navegar a pantalla de restablecer contraseña
                          },
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go(AppRouter.registro);
                          },
                          child: const Text(
                            'Crear cuenta',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
