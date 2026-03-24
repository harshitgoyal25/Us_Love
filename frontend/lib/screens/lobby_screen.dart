import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/socket_service.dart';
import '../models/room_model.dart';
import '../core/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../widgets/app_drawer.dart';

class LobbyScreen extends StatefulWidget {
  final RoomModel room;
  const LobbyScreen({super.key, required this.room});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with TickerProviderStateMixin {
  final SocketService _socket = SocketService();
  bool partnerConnected = false;
  late final AnimationController _pulseCtrl;
  late final AnimationController _cardEnterCtrl;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  String? _currentRole;
  String? _myUserId;

  final List<Map<String, dynamic>> games = [
    {'id': 'custom_quiz', 'title': 'How Well Do You Know Me?', 'emoji': '🎯', 'description': 'Test your knowledge of each other'},
    {'id': 'dots_and_boxes', 'title': 'Dots & Boxes', 'emoji': '🔳', 'description': 'Classic strategic board game'},
    {'id': 'co_draw', 'title': 'Shared Canvas', 'emoji': '🎨', 'description': 'Draw together in real time'},
    {'id': 'photobooth', 'title': 'Photobooth', 'emoji': '📸', 'description': 'Take 4 fun split-screen photos'},
  ];

  @override
  void initState() {
    super.initState();
    _currentRole = widget.room.role;
    _connectSocket();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _cardEnterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardFade = CurvedAnimation(parent: _cardEnterCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardEnterCtrl, curve: Curves.easeOut));
    _cardEnterCtrl.forward();
  }

  void _connectSocket() async {
    final auth = context.read<AuthProvider>();
    _myUserId = auth.userId;
    final token = auth.token ?? '';

    _socket.connect(
      roomId: widget.room.roomId,
      token: token,
      onConnected: () {
        if (_currentRole != 'HOST') {
          _socket.sendEvent(widget.room.roomId, {
            'type': 'PARTNER_JOINED',
            'payload': {'userId': _myUserId}
          });
          if (mounted) {
            setState(() => partnerConnected = true);
          }
        } else {
          _socket.sendEvent(widget.room.roomId, {
            'type': 'LOBBY_SYNC',
            'payload': {
              'action': 'LOBBY_SYNC',
              'userId': _myUserId,
            }
          });
        }
      },
      onMessage: (event) {
        final type = event['type'];
        if (type == 'PARTNER_JOINED') {
          setState(() => partnerConnected = true);
        } else if (type == 'PARTNER_LEFT') {
          setState(() => partnerConnected = false);
        } else if (type == 'ROOM_UPDATE') {
          final hostId = event['hostId']?.toString();
          final myId = _myUserId?.toString();
          
          if (hostId != null && myId != null && 
              hostId.trim().toLowerCase() == myId.trim().toLowerCase()) {
            if (mounted) {
              setState(() {
                _currentRole = 'HOST';
                partnerConnected = false;
              });
            }
          }
        } else if (type == 'GAME_START') {
          final game = event['game'];
          if (context.mounted) {
            context.go('/game/$game', extra: widget.room);
          }
        } else if (type == 'GAME_STATE_UPDATE') {
          final payload = event['payload'];
          if (payload != null) {
            if (payload['action'] == 'LOBBY_SYNC') {
              if (_currentRole != 'HOST') {
                _socket.sendEvent(widget.room.roomId, {'type': 'PARTNER_JOINED'});
              }
            } else if (payload['action'] == 'PARTNER_LEFT') {
              setState(() => partnerConnected = false);
            }
          }
        }
      },
    );
  }

  void _selectGame(String gameId) {
    _socket.sendEvent(widget.room.roomId, {
      'type': 'GAME_SELECTED',
      'game': gameId,
    });
  }

  @override
  void dispose() {
    _socket.disconnect();
    _pulseCtrl.dispose();
    _cardEnterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: FloatingHeartsBackground(
        child: Column(
          children: [
            // ── Frosted AppBar ──
            _FrostedAppBar(
              room: widget.room,
              partnerConnected: partnerConnected,
              pulseCtrl: _pulseCtrl,
              myUserId: _myUserId,
              socket: _socket,
            ),

            // ── Main Content ──
            Expanded(
              child: FadeTransition(
                opacity: _cardFade,
                child: SlideTransition(
                  position: _cardSlide,
                  child: _currentRole == 'HOST'
                      ? _buildHostView()
                      : _buildGuestView(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
          child: Column(
            children: [
              Text('Choose an Activity', style: AppTheme.display(28)),
              const SizedBox(height: 8),
              Text(
                partnerConnected
                    ? 'Your partner is ready. Pick a game! 💕'
                    : 'Waiting for your partner to join...',
                style: AppTheme.body(14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Expanded(
          child: _GameGrid(
            games: games,
            isEnabled: partnerConnected,
            isHost: true,
            onSelect: _selectGame,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
          child: Column(
            children: [
              Text('Available Games', style: AppTheme.display(28)),
              const SizedBox(height: 8),
              Text(
                'Waiting for the host to pick a game...',
                style: AppTheme.body(14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Expanded(
          child: _GameGrid(
            games: games,
            isEnabled: false,
            isHost: false,
            onSelect: (_) {},
          ),
        ),
      ],
    );
  }
}

// ── Frosted glass nav bar ──────────────────────────────────────────────────────
class _FrostedAppBar extends StatelessWidget {
  final RoomModel room;
  final bool partnerConnected;
  final AnimationController pulseCtrl;
  final String? myUserId;
  final SocketService socket;
  
  const _FrostedAppBar({
    required this.room,
    required this.partnerConnected,
    required this.pulseCtrl,
    required this.myUserId,
    required this.socket,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            bottom: 12,
            left: 24,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: AppTheme.bg1.withOpacity(0.75),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.rose.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Menu + Room code
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: AppTheme.rose),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Room Code:',
                    style: AppTheme.body(12,
                        color: AppTheme.textSecondary.withOpacity(0.6)),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: room.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Room code copied!',
                            style: AppTheme.body(13, color: Colors.white),
                          ),
                          backgroundColor: AppTheme.bg3,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.rose.withOpacity(0.15),
                            AppTheme.roseDark.withOpacity(0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppTheme.rose.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            room.code,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: AppTheme.rose,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Right: Partner status + logout
              Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: partnerConnected
                        ? Row(
                            key: const ValueKey('connected'),
                            children: [
                              AnimatedBuilder(
                                animation: pulseCtrl,
                                builder: (ctx, _) {
                                  return Transform.scale(
                                    scale: 1.0 + (pulseCtrl.value * 0.18),
                                    child: const Icon(
                                      Icons.favorite,
                                      color: AppTheme.rose,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Connected',
                                style: AppTheme.body(13,
                                    color: AppTheme.gold),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('waiting'),
                            children: [
                              const Icon(
                                Icons.favorite_border,
                                color: AppTheme.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Waiting...',
                                style: AppTheme.body(13),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Glass styled Leave Room Button
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.bg3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: Text('Leave Room?', style: AppTheme.display(20)),
                          content: Text(
                            'Are you sure you want to leave this room?',
                            style: AppTheme.body(14),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('Cancel',
                                  style: AppTheme.body(14)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                socket.sendEvent(room.roomId, {
                                  'type': 'GAME_ACTION',
                                  'payload': {
                                    'action': 'PARTNER_LEFT',
                                    'userId': myUserId,
                                  }
                                });
                                if (context.mounted) {
                                  context.go('/home');
                                }
                              },
                              child: Text(
                                'Leave',
                                style: AppTheme.body(14,
                                    color: AppTheme.rose),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        'Leave Room',
                        style: AppTheme.label(12).copyWith(
                          color: AppTheme.rose,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Responsive game grid ───────────────────────────────────────────────────────
class _GameGrid extends StatelessWidget {
  final List<Map<String, dynamic>> games;
  final bool isEnabled;
  final bool isHost;
  final void Function(String) onSelect;

  const _GameGrid({
    required this.games,
    required this.isEnabled,
    required this.isHost,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 3 : 2;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8)
          .copyWith(bottom: 32),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _GameCard(
          game: game,
          isEnabled: isEnabled,
          isHost: isHost,
          onTap: () => onSelect(game['id']),
        );
      },
    );
  }
}

// ── Game card with hover effect ────────────────────────────────────────────────
class _GameCard extends StatefulWidget {
  final Map<String, dynamic> game;
  final bool isEnabled;
  final bool isHost;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.isEnabled,
    required this.isHost,
    required this.onTap,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled;

    return MouseRegion(
      onEnter: (_) {
        if (enabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (enabled) setState(() => _isHovered = false);
      },
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) {
          if (enabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (enabled) {
            setState(() => _isPressed = false);
            widget.onTap();
          }
        },
        onTapCancel: () {
          if (enabled) setState(() => _isPressed = false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _isPressed
                ? AppTheme.bg2
                : _isHovered
                    ? AppTheme.bg3
                    : enabled
                        ? AppTheme.bg3.withOpacity(0.85)
                        : AppTheme.bg2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: enabled && _isHovered
                  ? AppTheme.rose.withOpacity(0.3)
                  : AppTheme.rose.withOpacity(0.06),
              width: 1,
            ),
            boxShadow: enabled && _isHovered && !_isPressed
                ? [
                    BoxShadow(
                      color: AppTheme.rose.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: AppTheme.shadowAmbient,
                      blurRadius: 20,
                      offset: Offset.zero,
                    )
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: enabled && _isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Opacity(
                  opacity: enabled ? 1.0 : 0.35,
                  child: Text(
                    widget.game['emoji'],
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  widget.game['title'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary.withOpacity(0.5),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  enabled
                      ? widget.game['description']
                      : widget.isHost
                          ? 'Waiting for partner...'
                          : 'Host is deciding...',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(11).copyWith(
                    color: enabled
                        ? AppTheme.textSecondary.withOpacity(0.6)
                        : AppTheme.textSecondary.withOpacity(0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
