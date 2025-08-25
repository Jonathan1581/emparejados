import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emparejados/models/usuario.model.dart';
import 'package:emparejados/providers/auth.provider.dart';
import 'package:emparejados/repositories/storage.repository.dart';
import 'package:emparejados/utils/logger.dart';
import 'package:emparejados/widgets/custom_button.widget.dart';
import 'package:emparejados/widgets/custom_text_field.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class EditarPerfilWidget extends ConsumerStatefulWidget {
  final Usuario usuario;
  final VoidCallback? onPerfilActualizado;

  const EditarPerfilWidget({
    super.key,
    required this.usuario,
    this.onPerfilActualizado,
  });

  @override
  ConsumerState<EditarPerfilWidget> createState() => _EditarPerfilWidgetState();
}

class _EditarPerfilWidgetState extends ConsumerState<EditarPerfilWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _bioController = TextEditingController();

  late String _genero;
  late String _generoInteres;
  late List<String> _intereses;

  bool _isLoading = false;

  // Variables para manejo de fotos
  final List<String> _fotosExistentes = [];
  final List<File> _fotosNuevas = [];
  final ImagePicker _picker = ImagePicker();
  final StorageRepository _storageRepository = StorageRepository();

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
  void initState() {
    super.initState();
    _inicializarControladores();
  }

  void _inicializarControladores() {
    _nombreController.text = widget.usuario.nombre;
    _apellidoController.text = widget.usuario.apellido;
    _bioController.text = widget.usuario.bio;
    _genero = widget.usuario.genero;
    _generoInteres = widget.usuario.generoInteres;
    _intereses = List.from(widget.usuario.intereses);

    // Inicializar fotos existentes
    _fotosExistentes.addAll(widget.usuario.fotos);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _bioController.dispose();
    super.dispose();
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

  // Métodos para manejo de fotos
  Future<void> _mostrarOpcionesFoto() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarFoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _tomarFoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _recortarImagen(File(image.path));
      }
    } catch (e) {
      logError('Error al seleccionar foto', e);
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        await _recortarImagen(File(image.path));
      }
    } catch (e) {
      logError('Error al tomar foto', e);
    }
  }

  Future<void> _recortarImagen(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar Foto',
            toolbarColor: const Color(0xFFFF6B6B),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Recortar Foto',
            aspectRatioLockEnabled: true,
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() {
          if (_fotosExistentes.length + _fotosNuevas.length < 5) {
            _fotosNuevas.add(File(croppedFile.path));
          }
        });
      }
    } catch (e) {
      logError('Error al recortar imagen', e);
    }
  }

  void _eliminarFotoExistente(int index) {
    if (!mounted) {
      return;
    }
    setState(() {
      _fotosExistentes.removeAt(index);
    });
  }

  void _eliminarFotoNueva(int index) {
    if (!mounted) {
      return;
    }
    setState(() {
      _fotosNuevas.removeAt(index);
    });
  }

  void _hacerFotoPrincipal(int index) {
    if (index == 0) {
      return;
    }

    setState(() {
      final foto = _fotosExistentes.removeAt(index);
      _fotosExistentes.insert(0, foto);
    });
  }

  void _hacerFotoPrincipalNueva(int index) {
    setState(() {
      final foto = _fotosNuevas.removeAt(index);
      // Convertir la foto nueva a String (URL temporal) para insertarla en existentes
      _fotosExistentes.insert(0, foto.path);
    });
  }

  void _moverFotoArriba(int index) {
    if (index > 0) {
      setState(() {
        final foto = _fotosExistentes.removeAt(index);
        _fotosExistentes.insert(index - 1, foto);
      });
    }
  }

  void _moverFotoAbajo(int index) {
    if (index < _fotosExistentes.length - 1) {
      setState(() {
        final foto = _fotosExistentes.removeAt(index);
        _fotosExistentes.insert(index + 1, foto);
      });
    }
  }

  // Funciones para reordenar fotos nuevas
  void _moverFotoNuevaArriba(int index) {
    if (index > 0) {
      setState(() {
        final foto = _fotosNuevas.removeAt(index);
        _fotosNuevas.insert(index - 1, foto);
      });
    }
  }

  void _moverFotoNuevaAbajo(int index) {
    if (index < _fotosNuevas.length - 1) {
      setState(() {
        final foto = _fotosNuevas.removeAt(index);
        _fotosNuevas.insert(index + 1, foto);
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      logInfo('Guardando cambios del perfil...');

      // Subir fotos nuevas si las hay
      List<String> todasLasFotos = List.from(_fotosExistentes);

      if (_fotosNuevas.isNotEmpty) {
        logInfo('Subiendo ${_fotosNuevas.length} fotos nuevas...');

        for (final foto in _fotosNuevas) {
          try {
            final url = await _storageRepository.subirImagenPerfil(
                foto, widget.usuario.id);
            todasLasFotos.add(url);
            logInfo('Foto subida exitosamente: $url');
          } catch (e) {
            logError('Error al subir foto', e);
            throw Exception('Error al subir una de las fotos: ${e.toString()}');
          }
        }
      }

      // Crear usuario actualizado con las fotos combinadas
      final usuarioActualizado = Usuario(
        id: widget.usuario.id,
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: widget.usuario.email,
        fechaNacimiento: widget.usuario.fechaNacimiento,
        genero: _genero,
        generoInteres: _generoInteres,
        fotos: todasLasFotos,
        bio: _bioController.text.trim(),
        latitud: widget.usuario.latitud,
        longitud: widget.usuario.longitud,
        intereses: _intereses,
        fechaCreacion: widget.usuario.fechaCreacion,
      );

      // Actualizar en Firebase
      await ref
          .read(authProvider.notifier)
          .actualizarPerfil(usuarioActualizado);

      logInfo('Perfil actualizado exitosamente');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Cerrar modal y notificar actualización
        Navigator.pop(context);
        widget.onPerfilActualizado?.call();
      }
    } catch (e) {
      logError('Error al actualizar perfil', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar perfil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header con barra de arrastre y título
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B6B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Barra de arrastre
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Título
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Editar Perfil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance del layout
                  ],
                ),
              ],
            ),
          ),

          // Contenido del formulario
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 24),

                    // Bio
                    CustomTextField(
                      controller: _bioController,
                      hintText: 'Cuéntanos sobre ti...',
                      prefixIcon: Icons.edit,
                      maxLines: 4,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 24),

                    // Género
                    _buildDropdown(
                      icon: Icons.person_outline,
                      title: 'Género',
                      items: _generos,
                      value: _genero,
                      onChanged: (value) {
                        setState(() {
                          _genero = value ?? _genero;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Género de interés
                    _buildDropdown(
                      icon: Icons.favorite_outline,
                      title: 'Género de tu interés',
                      items: _generos,
                      value: _generoInteres,
                      onChanged: (value) {
                        setState(() {
                          _generoInteres = value ?? _generoInteres;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Intereses
                    _buildIntereses(),
                    const SizedBox(height: 24),

                    // Fotos
                    _buildSeccionFotos(),
                    const SizedBox(height: 32),

                    // Botón de guardar
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Guardar Cambios',
                        onPressed: _isLoading ? null : _guardarCambios,
                        isLoading: _isLoading,
                        backgroundColor: const Color(0xFFFF6B6B),
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String title,
    required List<String> items,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildIntereses() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
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
          const SizedBox(height: 16),
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
                    color: isSelected ? const Color(0xFFFF6B6B) : Colors.white,
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

  Widget _buildSeccionFotos() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Fotos (${_fotosExistentes.length + _fotosNuevas.length}/5)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Información sobre foto principal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFFFF6B6B),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La primera foto será tu foto principal de perfil',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Grid de fotos existentes
          if (_fotosExistentes.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _fotosExistentes.length,
              itemBuilder: (context, index) {
                return _buildFotoExistente(index);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Grid de fotos nuevas
          if (_fotosNuevas.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _fotosNuevas.length,
              itemBuilder: (context, index) {
                return _buildFotoNueva(index);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Botón para agregar foto
          if (_fotosExistentes.length + _fotosNuevas.length < 5)
            _buildAddPhotoButton(),
        ],
      ),
    );
  }

  Widget _buildFotoExistente(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: index == 0 ? const Color(0xFFFF6B6B) : Colors.grey[300]!,
              width: index == 0 ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: _fotosExistentes[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.photo, color: Colors.grey),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
        ),

        // Indicador de foto principal
        if (index == 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),

        // Botones de acción
        Positioned(
          bottom: 4,
          right: 4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón eliminar
              GestureDetector(
                onTap: () => _eliminarFotoExistente(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Botones de reordenamiento
        if (index > 0)
          Positioned(
            top: 4,
            left: 4,
            child: GestureDetector(
              onTap: () => _hacerFotoPrincipal(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),

        if (index > 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón mover arriba
                GestureDetector(
                  onTap: () => _moverFotoArriba(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Botón mover abajo
                if (index < _fotosExistentes.length - 1)
                  GestureDetector(
                    onTap: () => _moverFotoAbajo(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFotoNueva(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _fotosNuevas[index],
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Botón eliminar
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _eliminarFotoNueva(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),

        // Botón hacer foto principal
        Positioned(
          top: 4,
          left: 4,
          child: GestureDetector(
            onTap: () => _hacerFotoPrincipalNueva(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),

        // Botones de reordenamiento
        Positioned(
          bottom: 4,
          left: 4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                              // Botón mover arriba
                if (index > 0)
                  GestureDetector(
                    onTap: () => _moverFotoNuevaArriba(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    child: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              if (index > 0) const SizedBox(width: 4),
                                // Botón mover abajo
                  if (index < _fotosNuevas.length - 1)
                    GestureDetector(
                      onTap: () => _moverFotoNuevaAbajo(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _mostrarOpcionesFoto,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              'Agregar Foto',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
