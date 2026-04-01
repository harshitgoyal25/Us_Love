import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/app_theme.dart';
import '../../core/socket_service.dart';
import '../../models/room_model.dart';
import '../../widgets/shared_game_widgets.dart';

class DrawingPoint {
  final Offset? offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

class CoDrawScreen extends StatefulWidget {
  final RoomModel room;

  const CoDrawScreen({super.key, required this.room});

  @override
  State<CoDrawScreen> createState() => _CoDrawScreenState();
}

class _CoDrawScreenState extends State<CoDrawScreen> {
  final SocketService _socket = SocketService();
  final GlobalKey _globalKey = GlobalKey();

  String _myId = '';
  List<DrawingPoint> _myPoints = [];
  List<DrawingPoint> _partnerPoints = [];

  Color _selectedColor = AppTheme.rose;
  double _strokeWidth = 4.0;

  final List<Color> _colors = [
    AppTheme.rose,
    AppTheme.gold,
    Color(0xFF9CF6F6), // Cyan glow
    Color(0xFFEAE0E1), // White
  ];

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  Future<void> _connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    _myId = prefs.getString('userId') ?? '';
    _socket.connect(
      roomId: widget.room.roomId,
      token: prefs.getString('token') ?? '',
      onConnected: () {},
      onMessage: _handleMessage,
    );
  }

  void _handleMessage(dynamic event) {
    if (event['type'] == 'GAME_STATE_UPDATE') {
      final payload = event['payload'];
      if (payload != null) {
        final action = payload['action'];
        if (action == 'DRAW') {
          String? senderId = payload['userId'];
          if (senderId != null && senderId == _myId && senderId.isNotEmpty)
            return;

          double? x = payload['x']?.toDouble();
          double? y = payload['y']?.toDouble();
          String hex = payload['color'];
          double width = payload['width']?.toDouble() ?? 4.0;
          bool isEnd = payload['isEnd'] ?? false;

          Color color = Color(int.parse(hex));

          setState(() {
            if (isEnd) {
              _partnerPoints.add(DrawingPoint(offset: null, paint: Paint()));
            } else if (x != null && y != null) {
              _partnerPoints.add(
                DrawingPoint(
                  offset: Offset(x, y),
                  paint: Paint()
                    ..color = color
                    ..isAntiAlias = true
                    ..strokeWidth = width
                    ..strokeCap = StrokeCap.round,
                ),
              );
            }
          });
        } else if (action == 'CLEAR') {
          setState(() {
            _myPoints.clear();
            _partnerPoints.clear();
          });
        } else if (action == 'BACK_TO_LOBBY') {
          if (mounted) {
            context.go('/lobby', extra: widget.room);
          }
        }
      }
    }
  }

  void _addPoint(Offset? offset) {
    setState(() {
      if (offset != null) {
        _myPoints.add(
          DrawingPoint(
            offset: offset,
            paint: Paint()
              ..color = _selectedColor
              ..isAntiAlias = true
              ..strokeWidth = _strokeWidth
              ..strokeCap = StrokeCap.round,
          ),
        );
        _sendDrawEvent(offset, false);
      } else {
        _myPoints.add(DrawingPoint(offset: null, paint: Paint()));
        _sendDrawEvent(null, true);
      }
    });
  }

  void _sendDrawEvent(Offset? offset, bool isEnd) {
    _socket.sendEvent(widget.room.roomId, {
      'type': 'GAME_ACTION',
      'payload': {
        'action': 'DRAW',
        'userId': _myId,
        'x': offset?.dx,
        'y': offset?.dy,
        'color': '0x${_selectedColor.value.toRadixString(16).padLeft(8, '0')}',
        'width': _strokeWidth,
        'isEnd': isEnd,
      },
    });
  }

  void _clearCanvas() {
    setState(() {
      _myPoints.clear();
      _partnerPoints.clear();
    });
    _socket.sendEvent(widget.room.roomId, {
      'type': 'GAME_ACTION',
      'payload': {'action': 'CLEAR'},
    });
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }

  Future<void> _saveCanvas() async {
    // Request permissions
    if (!kIsWeb) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
    }

    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final fileName = "CoDraw_${DateTime.now().millisecondsSinceEpoch}";

      final String resultPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: buffer,
        ext: "png",
        mimeType: MimeType.png,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultPath.isNotEmpty
                  ? 'Masterpiece saved!'
                  : 'Failed to save image.',
              style: AppTheme.body(14, color: AppTheme.textPrimary),
            ),
            backgroundColor: AppTheme.bg3,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: SharedGameAppBar(
        room: widget.room,
        socket: _socket,
        title: 'Co-Draw',
      ),
      body: FloatingHeartsBackground(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            ),

            // Canvas Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: AppTheme.velvetCard(),
                  clipBehavior: Clip.hardEdge,
                  child: RepaintBoundary(
                    key: _globalKey,
                    child: Container(
                      color: AppTheme.bg1, // Drawing background
                      child: GestureDetector(
                        onPanStart: (details) =>
                            _addPoint(details.localPosition),
                        onPanUpdate: (details) =>
                            _addPoint(details.localPosition),
                        onPanEnd: (details) => _addPoint(null),
                        child: CustomPaint(
                          painter: DrawingPainter(
                            myPoints: _myPoints,
                            partnerPoints: _partnerPoints,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tools Area
            Container(
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
              ),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _colors
                        .map(
                          (color) => GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColor == color
                                      ? AppTheme.textPrimary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppTheme.shadowAmbient,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: _clearCanvas,
                        tooltip: 'Clear',
                      ),
                      Expanded(
                        child: Slider(
                          value: _strokeWidth,
                          min: 2.0,
                          max: 20.0,
                          activeColor: AppTheme.rose,
                          inactiveColor: AppTheme.bg2,
                          onChanged: (val) =>
                              setState(() => _strokeWidth = val),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.save_alt, color: AppTheme.gold),
                        onPressed: _saveCanvas,
                        tooltip: 'Save to Gallery',
                      ),
                    ],
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

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> myPoints;
  final List<DrawingPoint> partnerPoints;

  DrawingPainter({required this.myPoints, required this.partnerPoints});

  @override
  void paint(Canvas canvas, Size size) {
    _drawList(canvas, myPoints);
    _drawList(canvas, partnerPoints);
  }

  void _drawList(Canvas canvas, List<DrawingPoint> points) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        // Draw line between points
        canvas.drawLine(
          points[i].offset!,
          points[i + 1].offset!,
          points[i].paint,
        );
      } else if (points[i].offset != null && points[i + 1].offset == null) {
        // Draw point
        canvas.drawPoints(ui.PointMode.points, [
          points[i].offset!,
        ], points[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
