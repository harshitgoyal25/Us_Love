import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../models/room_model.dart';
import '../core/socket_service.dart';

class SharedGameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final RoomModel room;
  final SocketService socket;
  final String title;

  const SharedGameAppBar({
    super.key,
    required this.room,
    required this.socket,
    required this.title,
  });

  void _backToLobby(BuildContext context) {
    socket.sendEvent(room.roomId, {
      'type': 'GAME_ACTION',
      'payload': {'action': 'BACK_TO_LOBBY'}
    });
    context.go('/lobby', extra: room);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: BackButton(
        color: AppTheme.textPrimary,
        onPressed: () => _backToLobby(context),
      ),
      title: Text(title, style: AppTheme.display(20)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          color: AppTheme.rose,
          tooltip: 'Leave Game',
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.bg3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text('Leave Game?', style: AppTheme.display(20)),
                content: Text('This will cancel the game for both players.', style: AppTheme.body(14)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: AppTheme.body(14)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _backToLobby(context);
                    },
                    child: Text('Leave', style: AppTheme.body(14, color: AppTheme.rose)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class SharedLeaveGameButton extends StatelessWidget {
  final RoomModel room;
  final SocketService socket;

  const SharedLeaveGameButton({
    super.key,
    required this.room,
    required this.socket,
  });

  void _backToLobby(BuildContext context) {
    socket.sendEvent(room.roomId, {
      'type': 'GAME_ACTION',
      'payload': {'action': 'BACK_TO_LOBBY'}
    });
    context.go('/lobby', extra: room);
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme.roseButton(
      label: 'Back to Lobby',
      onTap: () => _backToLobby(context),
    );
  }
}
