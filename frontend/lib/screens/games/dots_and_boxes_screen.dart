import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../../models/room_model.dart';
import '../../core/socket_service.dart';
import '../../widgets/shared_game_widgets.dart';

class DotsAndBoxesScreen extends StatefulWidget {
  final RoomModel room;
  const DotsAndBoxesScreen({super.key, required this.room});

  @override
  State<DotsAndBoxesScreen> createState() => _DotsAndBoxesScreenState();
}

class _DotsAndBoxesScreenState extends State<DotsAndBoxesScreen> {
  final SocketService _socket = SocketService();
  String? _myId;
  String? _myName;
  String? _partnerId;
  String? _partnerName;

  final int rows = 5; // 5 dots per row
  final int cols = 5; // 5 dots per col

  // State
  late List<List<String?>> horizontalLines; // rows x (cols-1)
  late List<List<String?>> verticalLines; // (rows-1) x cols
  late List<List<String?>> boxes; // (rows-1) x (cols-1)

  int myScore = 0;
  int partnerScore = 0;
  bool isMyTurn = false;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    _initGameState();
    _loadUserAndConnect();
  }

  void _initGameState() {
    horizontalLines = List.generate(rows, (_) => List.filled(cols - 1, null));
    verticalLines = List.generate(rows - 1, (_) => List.filled(cols, null));
    boxes = List.generate(rows - 1, (_) => List.filled(cols - 1, null));
    isMyTurn = widget.room.isHost; // host goes first by default
  }

  Future<void> _loadUserAndConnect() async {
    final prefs = await SharedPreferences.getInstance();
    _myId = prefs.getString('userId');
    _myName = prefs.getString('name') ?? '';

    _socket.connect(
      roomId: widget.room.roomId,
      token: prefs.getString('token') ?? '',
      onConnected: () {
        _socket.sendEvent(widget.room.roomId, {
          'type': 'GAME_ACTION',
          'payload': {
            'action': 'SYNC_PLAYER',
            'userId': _myId,
            'userName': _myName,
          },
        });
      },
      onMessage: (event) {
        final type = event['type'];
        if (type == 'GAME_STATE_UPDATE') {
          final payload = event['payload'];
          if (payload != null) {
            _handleGameAction(payload);
          }
        }
      },
    );
  }

  void _handleGameAction(Map<String, dynamic> payload) {
    if (!mounted) return;

    final action = payload['action'];
    if (action == 'SYNC_PLAYER') {
      if (payload['userId'] != _myId) {
        setState(() {
          _partnerId = payload['userId'];
          _partnerName = payload['userName'];
        });

        // Acknowledge logic to resolve race conditions
        if (payload['isAck'] != true) {
          _socket.sendEvent(widget.room.roomId, {
            'type': 'GAME_ACTION',
            'payload': {
              'action': 'SYNC_PLAYER',
              'userId': _myId,
              'userName': _myName,
              'isAck': true, // Prevent infinite loop syncing
            },
          });
        }
      }
    } else if (action == 'DRAW_LINE') {
      final String lineType = payload['lineType'];
      final int r = payload['r'];
      final int c = payload['c'];
      final String playerId = payload['userId'];

      if (playerId == _myId) return;

      _applyLine(lineType, r, c, playerId);
    } else if (action == 'BACK_TO_LOBBY') {
      if (mounted) {
        context.go('/lobby', extra: widget.room);
      }
    }
  }

  void _applyLine(String lineType, int r, int c, String playerId) {
    setState(() {
      if (lineType == 'horizontal') {
        horizontalLines[r][c] = playerId;
      } else {
        verticalLines[r][c] = playerId;
      }

      bool boxCompleted = false;

      if (lineType == 'horizontal') {
        if (r > 0 && _isBoxComplete(r - 1, c)) {
          if (boxes[r - 1][c] == null) {
            boxes[r - 1][c] = playerId;
            boxCompleted = true;
          }
        }
        if (r < rows - 1 && _isBoxComplete(r, c)) {
          if (boxes[r][c] == null) {
            boxes[r][c] = playerId;
            boxCompleted = true;
          }
        }
      } else {
        if (c > 0 && _isBoxComplete(r, c - 1)) {
          if (boxes[r][c - 1] == null) {
            boxes[r][c - 1] = playerId;
            boxCompleted = true;
          }
        }
        if (c < cols - 1 && _isBoxComplete(r, c)) {
          if (boxes[r][c] == null) {
            boxes[r][c] = playerId;
            boxCompleted = true;
          }
        }
      }

      _recalculateScores();

      if (!boxCompleted) {
        isMyTurn = (playerId != _myId);
      } else {
        isMyTurn = (playerId == _myId);
      }

      _checkGameOver();
    });
  }

  bool _isBoxComplete(int r, int c) {
    return horizontalLines[r][c] != null &&
        horizontalLines[r + 1][c] != null &&
        verticalLines[r][c] != null &&
        verticalLines[r][c + 1] != null;
  }

  void _recalculateScores() {
    int myS = 0;
    int partnerS = 0;
    for (int r = 0; r < rows - 1; r++) {
      for (int c = 0; c < cols - 1; c++) {
        if (boxes[r][c] == _myId)
          myS++;
        else if (boxes[r][c] != null)
          partnerS++;
      }
    }
    myScore = myS;
    partnerScore = partnerS;
  }

  void _checkGameOver() {
    bool allClaimed = true;
    for (int r = 0; r < rows - 1; r++) {
      for (int c = 0; c < cols - 1; c++) {
        if (boxes[r][c] == null) {
          allClaimed = false;
          break;
        }
      }
    }

    if (allClaimed && !isGameOver) {
      isGameOver = true;
      if (widget.room.isHost) {
        String? winnerId;
        if (myScore > partnerScore)
          winnerId = _myId;
        else if (partnerScore > myScore)
          winnerId = _partnerId;

        _socket.sendEvent(widget.room.roomId, {
          'type': 'GAME_END',
          'payload': {
            'scoreA': myScore,
            'scoreB': partnerScore,
            'winnerId': winnerId,
          },
        });
      }
    }
  }

  void _onLineTap(String lineType, int r, int c) {
    if (!isMyTurn || isGameOver) return;

    if (lineType == 'horizontal' && horizontalLines[r][c] != null) return;
    if (lineType == 'vertical' && verticalLines[r][c] != null) return;

    _socket.sendEvent(widget.room.roomId, {
      'type': 'GAME_ACTION',
      'payload': {
        'action': 'DRAW_LINE',
        'lineType': lineType,
        'r': r,
        'c': c,
        'userId': _myId,
      },
    });

    _applyLine(lineType, r, c, _myId!);
  }

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg1,
      appBar: SharedGameAppBar(
        room: widget.room,
        socket: _socket,
        title: 'Dots & Boxes',
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildScoreboard(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AspectRatio(aspectRatio: 1.0, child: _buildGrid()),
                ),
              ),
            ),
            if (isGameOver)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      myScore > partnerScore
                          ? '🎉 You Win!'
                          : (partnerScore > myScore
                                ? '${_partnerName ?? "Partner"} Wins!'
                                : 'It\'s a Tie!'),
                      style: AppTheme.display(
                        28,
                      ).copyWith(color: AppTheme.rose),
                    ),
                    const SizedBox(height: 16),
                    SharedLeaveGameButton(room: widget.room, socket: _socket),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  isMyTurn
                      ? "Your Turn!"
                      : "Waiting for ${_partnerName ?? 'Partner'}...",
                  style: AppTheme.display(20).copyWith(
                    color: isMyTurn ? AppTheme.rose : AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreboard() {
    Color myColor = widget.room.isHost ? AppTheme.rose : AppTheme.gold;
    Color partnerColor = widget.room.isHost ? AppTheme.gold : AppTheme.rose;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScorePill('You', myScore, myColor),
          _buildScorePill(
            _partnerName ?? 'Partner',
            partnerScore,
            partnerColor,
          ),
        ],
      ),
    );
  }

  Color _getPlayerColor(String id) {
    if (widget.room.isHost) {
      return id == _myId ? AppTheme.rose : AppTheme.gold;
    } else {
      return id == _myId ? AppTheme.gold : AppTheme.rose;
    }
  }

  Widget _buildScorePill(String name, int score, Color teamColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: AppTheme.velvetCard(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: AppTheme.body(14)),
          const SizedBox(width: 12),
          Text(
            score.toString(),
            style: AppTheme.display(24).copyWith(color: teamColor),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Column(
      children: List.generate(rows * 2 - 1, (index) {
        if (index % 2 == 0) {
          int r = index ~/ 2;
          return Row(
            children: List.generate(cols * 2 - 1, (colIndex) {
              if (colIndex % 2 == 0)
                return _buildDot();
              else
                return Expanded(child: _buildHorizontalLine(r, colIndex ~/ 2));
            }),
          );
        } else {
          int r = index ~/ 2;
          return Expanded(
            child: Row(
              children: List.generate(cols * 2 - 1, (colIndex) {
                if (colIndex % 2 == 0)
                  return _buildVerticalLine(r, colIndex ~/ 2);
                else
                  return Expanded(child: _buildBox(r, colIndex ~/ 2));
              }),
            ),
          );
        }
      }),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: AppTheme.textPrimary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.textSecondary.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLine(int r, int c) {
    String? ownerId = horizontalLines[r][c];
    Color lineColor = ownerId == null ? AppTheme.bg2 : _getPlayerColor(ownerId);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onLineTap('horizontal', r, c),
      child: Container(
        height: 30, // Touch target
        alignment: Alignment.center,
        child: Container(
          height: 8,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: ownerId == null
                ? []
                : [
                    BoxShadow(
                      color: lineColor.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalLine(int r, int c) {
    String? ownerId = verticalLines[r][c];
    Color lineColor = ownerId == null ? AppTheme.bg2 : _getPlayerColor(ownerId);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onLineTap('vertical', r, c),
      child: Container(
        width: 30, // Touch target
        alignment: Alignment.center,
        child: Container(
          width: 8,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: ownerId == null
                ? []
                : [
                    BoxShadow(
                      color: lineColor.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildBox(int r, int c) {
    String? ownerId = boxes[r][c];
    bool isFilled = ownerId != null;
    Color? boxColor = isFilled ? _getPlayerColor(ownerId) : null;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: !isFilled ? Colors.transparent : boxColor!.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: !isFilled
            ? null
            : Border.all(color: boxColor!.withOpacity(0.5), width: 2),
      ),
      child: !isFilled
          ? null
          : Center(
              child: Text(
                ownerId == _myId
                    ? _getInitial(_myName)
                    : _getInitial(_partnerName),
                style: AppTheme.display(24).copyWith(color: boxColor),
              ),
            ),
    );
  }
}
