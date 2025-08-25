import 'package:emparejados/models/match.model.dart';
import 'package:emparejados/models/mensaje.model.dart';
import 'package:emparejados/models/usuario.model.dart';
import 'package:emparejados/providers/auth.provider.dart';
import 'package:emparejados/providers/emparejamiento.provider.dart';
import 'package:emparejados/providers/usuario.provider.dart';
import 'package:emparejados/repositories/matches.repository.dart';
import 'package:emparejados/repositories/mensajes.repository.dart';
import 'package:emparejados/repositories/usuarios.repository.dart';
import 'package:emparejados/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Chats',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B6B),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            // Indicador de notificaciones de likes
            Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authProvider);
                final usuarioActualId = authState.usuario?.id;

                if (usuarioActualId == null) {
                  return const SizedBox.shrink();
                }

                return StreamBuilder<List<Match>>(
                  stream: MatchesRepository()
                      .obtenerNotificacionesLikes(usuarioActualId),
                  builder: (context, snapshot) {
                    final likesRecibidos = snapshot.data ?? [];

                    if (likesRecibidos.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.favorite_border,
                              color: Color(0xFFFF6B6B),
                            ),
                            onPressed: () {
                              // Cambiar al tab de likes recibidos (ahora es el índice 1)
                              DefaultTabController.of(context).animateTo(1);
                            },
                            tooltip: 'Likes recibidos',
                          ),
                          if (likesRecibidos.isNotEmpty)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${likesRecibidos.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFFFF6B6B),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFFF6B6B),
            tabs: [
              Tab(text: 'Matches'),
              Tab(text: 'Likes Recibidos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MatchesTab(),
            _LikesRecibidosTab(),
          ],
        ),
      ),
    );
  }
}

class _MatchesTab extends ConsumerWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emparejamientoState = ref.watch(emparejamientoProvider);
    final authState = ref.watch(authProvider);
    final usuarioActualId = authState.usuario?.id;

    if (usuarioActualId == null) {
      return const Center(
        child: Text(
          'Usuario no autenticado',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    if (emparejamientoState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
        ),
      );
    }

    if (emparejamientoState.matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes matches aún',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Sigue deslizando para encontrar tu pareja ideal!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: emparejamientoState.matches.length,
      itemBuilder: (context, index) {
        final match = emparejamientoState.matches[index];
        return _MatchCard(match: match, ref: ref);
      },
    );
  }
}

class _MatchCard extends ConsumerWidget {
  final Match match;
  final WidgetRef ref;

  const _MatchCard({required this.match, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Usuario?>(
      future: _getOtroUsuario(match, ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              title: Text('Cargando...'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final otroUsuario = snapshot.data!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: otroUsuario.fotoPrincipal != null
                  ? NetworkImage(otroUsuario.fotoPrincipal!)
                  : null,
              child: otroUsuario.fotoPrincipal == null
                  ? Icon(Icons.person, size: 30, color: Colors.grey[400])
                  : null,
            ),
            title: Text(
              otroUsuario.nombreCompleto,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${otroUsuario.edad} años',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (match.fechaUltimoMensaje != null)
                  Text(
                    'Último mensaje: ${_formatearFecha(match.fechaUltimoMensaje!)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: match.mensajesNoLeidos > 0
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${match.mensajesNoLeidos}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              context.push('/chat-individual', extra: {
                'match': match,
                'otroUsuario': otroUsuario,
              });
            },
          ),
        );
      },
    );
  }

  Future<Usuario?> _getOtroUsuario(Match match, WidgetRef ref) async {
    final usuarioActualId = ref.read(usuarioIdProvider);
    if (usuarioActualId == null) {
      return null;
    }

    final otroUsuarioId = match.usuario1Id == usuarioActualId
        ? match.usuario2Id
        : match.usuario1Id;

    return await UsuariosRepository().obtenerUsuario(otroUsuarioId);
  }

  String _formatearFecha(DateTime fecha) {
    final now = DateTime.now();
    final diferencia = now.difference(fecha);

    if (diferencia.inDays > 0) {
      return '${diferencia.inDays}d';
    } else if (diferencia.inHours > 0) {
      return '${diferencia.inHours}h';
    } else if (diferencia.inMinutes > 0) {
      return '${diferencia.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }
}

class _LikesRecibidosTab extends ConsumerWidget {
  const _LikesRecibidosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final usuarioActualId = authState.usuario?.id;

    if (usuarioActualId == null) {
      return const Center(
        child: Text(
          'Usuario no autenticado',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return StreamBuilder<List<Match>>(
      stream: MatchesRepository().obtenerNotificacionesLikes(usuarioActualId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
            ),
          );
        }

        if (snapshot.hasError) {
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
                  'Error al cargar likes',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final likesRecibidos = snapshot.data ?? [];

        if (likesRecibidos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes likes aún',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¡Sigue deslizando para recibir likes!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: likesRecibidos.length,
          itemBuilder: (context, index) {
            final match = likesRecibidos[index];
            return _LikeRecibidoCard(match: match, ref: ref);
          },
        );
      },
    );
  }
}

class _LikeRecibidoCard extends ConsumerWidget {
  final Match match;
  final WidgetRef ref;

  const _LikeRecibidoCard({required this.match, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Usuario?>(
      future: _getUsuarioQueMeGusto(match, ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              title: Text('Cargando...'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final usuarioQueMeGusto = snapshot.data!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: usuarioQueMeGusto.fotoPrincipal != null
                  ? NetworkImage(usuarioQueMeGusto.fotoPrincipal!)
                  : null,
              child: usuarioQueMeGusto.fotoPrincipal == null
                  ? Icon(Icons.person, size: 30, color: Colors.grey[400])
                  : null,
            ),
            title: Text(
              usuarioQueMeGusto.nombreCompleto,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${usuarioQueMeGusto.edad} años',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Te dio like ${_formatearFecha(match.fechaMatch)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón para dar like de vuelta
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.favorite,
                        color: Colors.white, size: 20),
                    onPressed: () => _darLikeDeVuelta(context, ref),
                    tooltip: 'Dar like de vuelta',
                  ),
                ),
                const SizedBox(width: 8),
                // Botón para rechazar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                    onPressed: () => _rechazarLike(context, ref),
                    tooltip: 'Rechazar',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Usuario?> _getUsuarioQueMeGusto(Match match, WidgetRef ref) async {
    // El usuario que me dio like es usuario1Id
    return await UsuariosRepository().obtenerUsuario(match.usuario1Id);
  }

  String _formatearFecha(DateTime fecha) {
    final now = DateTime.now();
    final diferencia = now.difference(fecha);

    if (diferencia.inDays > 0) {
      return 'hace ${diferencia.inDays} días';
    } else if (diferencia.inHours > 0) {
      return 'hace ${diferencia.inHours} horas';
    } else if (diferencia.inMinutes > 0) {
      return 'hace ${diferencia.inMinutes} minutos';
    } else {
      return 'ahora';
    }
  }

  Future<void> _darLikeDeVuelta(BuildContext context, WidgetRef ref) async {
    try {
      logInfo('=== DANDO LIKE DE VUELTA ===');
      final authState = ref.read(authProvider);
      final usuarioActualId = authState.usuario?.id;

      logInfo('Usuario actual ID: $usuarioActualId');
      logInfo('Usuario objetivo ID: ${match.usuario1Id}');
      logInfo('Match ID: ${match.id}');

      if (usuarioActualId == null) {
        logWarning('Usuario no autenticado');
        return;
      }

      final matchesRepo = MatchesRepository();

      // Actualizar el match existente para convertirlo en match completo
      logInfo('Actualizando match existente...');
      await matchesRepo.actualizarMatchDespuesDelike(match.id);
      logInfo('Match actualizado exitosamente');

      // Actualizar el provider de emparejamiento para refrescar la UI
      logInfo('Refrescando provider de emparejamiento...');
      await ref.read(emparejamientoProvider.notifier).refrescarUsuarios();
      logInfo('Provider refrescado');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white),
                SizedBox(width: 8),
                Text('¡Match! Ahora pueden chatear'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      logError('Error al dar like de vuelta', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rechazarLike(BuildContext context, WidgetRef ref) async {
    try {
      logInfo('=== RECHAZANDO LIKE ===');
      logInfo('Match ID: ${match.id}');
      logInfo('Usuario que me dio like: ${match.usuario1Id}');

      // Eliminar el match
      await MatchesRepository().eliminarMatch(match.id);
      logInfo('Match eliminado exitosamente');

      // Actualizar el provider de emparejamiento para refrescar la UI
      logInfo('Refrescando provider de emparejamiento...');
      await ref.read(emparejamientoProvider.notifier).refrescarUsuarios();
      logInfo('Provider refrescado');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.close, color: Colors.white),
                SizedBox(width: 8),
                Text('Like rechazado'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      logError('Error al rechazar like', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ChatIndividualScreen extends ConsumerStatefulWidget {
  final Match match;
  final Usuario otroUsuario;

  const ChatIndividualScreen({
    super.key,
    required this.match,
    required this.otroUsuario,
  });

  @override
  ConsumerState<ChatIndividualScreen> createState() =>
      _ChatIndividualScreenState();
}

class _ChatIndividualScreenState extends ConsumerState<ChatIndividualScreen> {
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MensajesRepository _mensajesRepository = MensajesRepository();
  bool _enviandoMensaje = false; // Nuevo estado

  @override
  void initState() {
    super.initState();
    // Marcar mensajes como leídos cuando se abre el chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _marcarMensajesComoLeidos();
    });
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Marcar mensajes como leídos
  Future<void> _marcarMensajesComoLeidos() async {
    try {
      logInfo('=== MARCANDO MENSAJES COMO LEÍDOS ===');
      logInfo('Match ID: ${widget.match.id}');

      final authState = ref.read(authProvider);
      final usuarioActualId = authState.usuario?.id;

      if (usuarioActualId == null) {
        logError('Usuario no autenticado');
        return;
      }

      logInfo('Usuario actual ID: $usuarioActualId');
      logInfo('Llamando a repository para marcar como leídos...');

      await _mensajesRepository.marcarMensajesComoLeidos(
        widget.match.id,
        usuarioActualId,
      );

      logInfo('Mensajes marcados como leídos exitosamente');

      // Actualizar el estado local del match
      _actualizarEstadoLocal();

      // Mostrar feedback visual
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mensajes marcados como leídos'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      logError('Error al marcar mensajes como leídos', e);
    }
  }

  // Actualizar estado local del match
  void _actualizarEstadoLocal() {
    try {
      logInfo('=== ACTUALIZANDO ESTADO LOCAL ===');

      // Crear un match actualizado con mensajes no leídos = 0
      final matchActualizado = Match(
        id: widget.match.id,
        usuario1Id: widget.match.usuario1Id,
        usuario2Id: widget.match.usuario2Id,
        fechaMatch: widget.match.fechaMatch,
        usuario1Liked: widget.match.usuario1Liked,
        usuario2Liked: widget.match.usuario2Liked,
        esMatch: widget.match.esMatch,
        fechaUltimoMensaje: widget.match.fechaUltimoMensaje,
      );

      // Notificar al provider de emparejamiento que actualice el match
      ref
          .read(emparejamientoProvider.notifier)
          .actualizarMatchConObjeto(matchActualizado);

      logInfo('Estado local actualizado exitosamente');
    } catch (e) {
      logError('Error al actualizar estado local', e);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _enviarMensaje() async {
    if (_mensajeController.text.trim().isEmpty) {
      logInfo('Mensaje vacío, no se envía');
      return;
    }

    if (_enviandoMensaje) {
      logInfo('Ya se está enviando un mensaje, ignorando...');
      return;
    }

    try {
      if (!mounted) {
        return;
      }
      setState(() {
        _enviandoMensaje = true;
      });

      logInfo('=== ENVIANDO MENSAJE DESDE UI ===');
      logInfo('Match ID: ${widget.match.id}');
      logInfo('Contenido: ${_mensajeController.text.trim()}');

      final authState = ref.read(authProvider);
      final usuarioActualId = authState.usuario?.id;

      if (usuarioActualId == null) {
        logError('Usuario no autenticado');
        return;
      }

      logInfo('Usuario actual ID: $usuarioActualId');

      final mensaje = Mensaje(
        id: '',
        matchId: widget.match.id,
        remitenteId: usuarioActualId,
        contenido: _mensajeController.text.trim(),
        fechaEnvio: DateTime.now(),
      );

      logInfo('Mensaje creado: $mensaje');
      logInfo('Llamando a repository para enviar...');

      await _mensajesRepository.enviarMensaje(mensaje);
      logInfo('Mensaje enviado exitosamente desde repository');

      _mensajeController.clear();
      logInfo('Campo de texto limpiado');

      // Scroll al final después de enviar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
        logInfo('Scroll al final ejecutado');
      });

      logInfo('=== MENSAJE ENVIADO COMPLETAMENTE ===');
    } catch (e) {
      logError('Error al enviar mensaje desde UI', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _enviandoMensaje = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otroUsuario.fotoPrincipal != null
                  ? NetworkImage(widget.otroUsuario.fotoPrincipal!)
                  : null,
              child: widget.otroUsuario.fotoPrincipal == null
                  ? Icon(Icons.person, color: Colors.grey[400])
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otroUsuario.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.otroUsuario.edad} años',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFF6B6B),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Lista de mensajes
            Expanded(
              child: StreamBuilder<List<Mensaje>>(
                stream: _mensajesRepository.obtenerMensajes(widget.match.id),
                builder: (context, snapshot) {
                  logInfo('=== STREAMBUILDER MENSAJES ===');
                  logInfo('Connection state: ${snapshot.connectionState}');
                  logInfo('Has data: ${snapshot.hasData}');
                  logInfo('Has error: ${snapshot.hasError}');
                  if (snapshot.hasError) {
                    logError('Error en snapshot: ${snapshot.error}');

                    // Si hay error de índice, mostrar mensaje informativo
                    if (snapshot.error
                        .toString()
                        .contains('failed-precondition')) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 80,
                              color: Colors.orange[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Configurando chat...',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.orange[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'El chat estará disponible en unos momentos',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Recargar la pantalla
                                setState(() {});
                              },
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    logInfo('Estado de espera, mostrando loading...');
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    logInfo('No hay mensajes, mostrando pantalla vacía');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '¡Inicia la conversación!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Envía el primer mensaje a ${widget.otroUsuario.nombre}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final mensajes = snapshot.data!;
                  logInfo('Mensajes recibidos: ${mensajes.length}');
                  logInfo('Primer mensaje: ${mensajes.first}');
                  logInfo('Último mensaje: ${mensajes.last}');

                  // Scroll al final cuando se cargan los mensajes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                    logInfo('Scroll automático al final ejecutado');
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: mensajes.length,
                    itemBuilder: (context, index) {
                      final mensaje = mensajes[index];
                      final authState = ref.read(authProvider);
                      final usuarioActualId = authState.usuario?.id;
                      final esMio = mensaje.remitenteId == usuarioActualId;

                      logInfo(
                          'Renderizando mensaje $index: ${mensaje.contenido} (esMio: $esMio)');

                      return _MensajeBurbuja(
                        mensaje: mensaje,
                        esMio: esMio,
                      );
                    },
                  );
                },
              ),
            ),

            // Campo de entrada de mensaje
            Container(
              padding: const EdgeInsets.all(16),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _mensajeController,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _enviarMensaje(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _enviandoMensaje
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _enviandoMensaje ? null : _enviarMensaje,
                      tooltip:
                          _enviandoMensaje ? 'Enviando...' : 'Enviar mensaje',
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
}

class _MensajeBurbuja extends StatelessWidget {
  final Mensaje mensaje;
  final bool esMio;

  const _MensajeBurbuja({
    required this.mensaje,
    required this.esMio,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: esMio ? const Color(0xFFFF6B6B) : Colors.grey[300],
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft:
                esMio ? const Radius.circular(20) : const Radius.circular(5),
            bottomRight:
                esMio ? const Radius.circular(5) : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mensaje.contenido,
              style: TextStyle(
                color: esMio ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mensaje.horaFormateada,
                  style: TextStyle(
                    color: esMio ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (esMio) ...[
                  const SizedBox(width: 8),
                  Icon(
                    mensaje.leido ? Icons.done_all : Icons.done,
                    size: 16,
                    color: mensaje.leido ? Colors.blue[300] : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
