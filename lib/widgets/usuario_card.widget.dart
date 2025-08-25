import 'package:cached_network_image/cached_network_image.dart';
import 'package:emparejados/models/usuario.model.dart';
import 'package:flutter/material.dart';

class UsuarioCard extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback onLike;
  final VoidCallback onReject;
  final VoidCallback onSuperLike;

  const UsuarioCard({
    super.key,
    required this.usuario,
    required this.onLike,
    required this.onReject,
    required this.onSuperLike,
  });

  @override
  State<UsuarioCard> createState() => _UsuarioCardState();
}

class _UsuarioCardState extends State<UsuarioCard> {
  int _currentImageIndex = 0;
  late PageController _imagePageController;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (_currentImageIndex < widget.usuario.fotos.length - 1 && mounted) {
      setState(() {
        _currentImageIndex++;
      });
      _imagePageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0 && mounted) {
      setState(() {
        _currentImageIndex--;
      });
      _imagePageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      height: MediaQuery.of(context).size.height *
          0.75, // 75% de la altura de la pantalla
      width: MediaQuery.of(context).size.width *
          0.9, // 90% del ancho de la pantalla
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Imagen de fondo
            _buildImagenFondo(),

            // Overlay con información del usuario
            _buildOverlayInformacion(),

            // Indicadores de imagen
            if (widget.usuario.fotos.length > 1) _buildIndicadoresImagen(),

            // Botones de navegación de imagen
            if (widget.usuario.fotos.length > 1) _buildBotonesNavegacion(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenFondo() {
    if (widget.usuario.fotos.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.person,
            size: 100,
            color: Colors.grey,
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _imagePageController,
      onPageChanged: (index) {
        if (mounted) {
          setState(() {
            _currentImageIndex = index;
          });
        }
      },
      itemCount: widget.usuario.fotos.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: widget.usuario.fotos[index],
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.error,
                size: 50,
                color: Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlayInformacion() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre y edad
            Row(
              children: [
                Text(
                  '${widget.usuario.nombre}, ${widget.usuario.edad}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Nota: Campo verificado eliminado para simplificar el emparejamiento
              ],
            ),
            const SizedBox(height: 8),

            // Bio
            if (widget.usuario.bio.isNotEmpty)
              Text(
                widget.usuario.bio,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 12),

            // Intereses
            if (widget.usuario.intereses.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.usuario.intereses.take(5).map((interes) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      interes,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicadoresImagen() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.usuario.fotos.length, (index) {
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentImageIndex
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBotonesNavegacion() {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // Botón izquierdo
          Expanded(
            child: GestureDetector(
              onTap: _previousImage,
              child: Container(
                color: Colors.transparent,
                child: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),

          // Botón derecho
          Expanded(
            child: GestureDetector(
              onTap: _nextImage,
              child: Container(
                color: Colors.transparent,
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
