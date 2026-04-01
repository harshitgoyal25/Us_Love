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
      'payload': {'action': 'BACK_TO_LOBBY'},
    });
    context.go('/lobby', extra: room);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(title, style: AppTheme.display(20)),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Tooltip(
            message: 'Leave Game',
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.bg3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text('Leave Game?', style: AppTheme.display(20)),
                    content: Text(
                      'This will cancel the game for both players.',
                      style: AppTheme.body(14),
                    ),
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
                        child: Text(
                          'Leave',
                          style: AppTheme.body(14, color: AppTheme.rose),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.rose.withOpacity(0.12),
                      AppTheme.bg1.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: AppTheme.rose.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Leave',
                  style: AppTheme.label(12).copyWith(
                    color: AppTheme.rose,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
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
      'payload': {'action': 'BACK_TO_LOBBY'},
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
