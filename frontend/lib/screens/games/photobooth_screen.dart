import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:permission_handler/permission_handler.dart';
import '../../core/app_theme.dart';
import '../../core/socket_service.dart';
import '../../models/room_model.dart';
import '../../widgets/shared_game_widgets.dart';

class PhotoboothScreen extends StatefulWidget {
  final RoomModel room;
  const PhotoboothScreen({super.key, required this.room});

  @override
  State<PhotoboothScreen> createState() => _PhotoboothScreenState();
}

class _PhotoboothScreenState extends State<PhotoboothScreen> with SingleTickerProviderStateMixin {
  final SocketService _socket = SocketService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _inCalling = false;
  String _myId = '';
  
  // Capturing State
  final GlobalKey _cameraRowKey = GlobalKey();
  final List<ui.Image> _capturedPhotos = [];
  bool _isFlashing = false;

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  Future<void> _initWebRTC() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    final prefs = await SharedPreferences.getInstance();
    _myId = prefs.getString('userId') ?? '';

    _socket.connect(
      roomId: widget.room.roomId,
      token: prefs.getString('token') ?? '',
      onConnected: () {
        _startLocalStream();
      },
      onMessage: _onSignalingMessage,
    );
  }

  Future<void> _startLocalStream() async {
    final mediaConstraints = {
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
      setState(() {});
      _createPeerConnection();
    } catch (e) {
      debugPrint("Error opening camera: $e");
    }
  }

  Future<void> _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final pcConstraints = {
      "mandatory": {},
      "optional": [
        {"DtlsSrtpKeyAgreement": true},
      ],
    };

    _peerConnection = await createPeerConnection(configuration, pcConstraints);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _socket.sendEvent(widget.room.roomId, {
        'type': 'GAME_ACTION',
        'payload': {
          'action': 'WEBRTC_ICE',
          'userId': _myId,
          'candidate': candidate.toMap(),
        }
      });
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      _remoteStream = stream;
      _remoteRenderer.srcObject = _remoteStream;
      setState(() {
        _inCalling = true;
      });
    };

    _localStream?.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    if (widget.room.isHost) {
      _createOffer();
    }
  }

  Future<void> _createOffer() async {
    RTCSessionDescription offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);
    
    _socket.sendEvent(widget.room.roomId, {
      'type': 'GAME_ACTION',
      'payload': {
        'action': 'WEBRTC_OFFER',
        'userId': _myId,
        'sdp': offer.toMap(),
      }
    });
  }

  Future<void> _createAnswer() async {
    RTCSessionDescription answer = await _peerConnection!.createAnswer({});
    await _peerConnection!.setLocalDescription(answer);
    
    _socket.sendEvent(widget.room.roomId, {
      'type': 'GAME_ACTION',
      'payload': {
        'action': 'WEBRTC_ANSWER',
        'userId': _myId,
        'sdp': answer.toMap(),
      }
    });
  }

  void _onSignalingMessage(dynamic event) async {
    if (event['type'] == 'GAME_STATE_UPDATE') {
      final payload = event['payload'];
      if (payload == null) return;
      
      final action = payload['action'];
      final senderId = payload['userId'];
      
      if (senderId == _myId && senderId != null) return; // ignore self
      
      if (action == 'WEBRTC_OFFER') {
        final sdpMap = payload['sdp'];
        await _peerConnection?.setRemoteDescription(
            RTCSessionDescription(sdpMap['sdp'], sdpMap['type']));
        await _createAnswer();
      } else if (action == 'WEBRTC_ANSWER') {
        final sdpMap = payload['sdp'];
        await _peerConnection?.setRemoteDescription(
            RTCSessionDescription(sdpMap['sdp'], sdpMap['type']));
      } else if (action == 'WEBRTC_ICE') {
        final candidateMap = payload['candidate'];
        await _peerConnection?.addCandidate(
            RTCIceCandidate(candidateMap['candidate'], candidateMap['sdpMid'], candidateMap['sdpMLineIndex']));
      } else if (action == 'TAKE_PHOTO') {
        _snapLocalPhoto();
      } else if (action == 'UNDO_PHOTO') {
        setState(() {
          if (_capturedPhotos.isNotEmpty) _capturedPhotos.removeLast();
        });
      }
    } else if (event['type'] == 'BACK_TO_LOBBY') {
        if (mounted) context.go('/lobby', extra: widget.room);
    }
  }

  void _triggerSnap() {
    if (_capturedPhotos.length >= 4) return;
    _socket.sendEvent(widget.room.roomId, {
      'type': 'GAME_ACTION',
      'payload': {'action': 'TAKE_PHOTO', 'userId': _myId}
    });
    _snapLocalPhoto();
  }

  void _triggerUndo() {
    if (_capturedPhotos.isEmpty) return;
    _socket.sendEvent(widget.room.roomId, {
      'type': 'GAME_ACTION',
      'payload': {'action': 'UNDO_PHOTO', 'userId': _myId}
    });
    setState(() {
      _capturedPhotos.removeLast();
    });
  }

  Future<void> _snapLocalPhoto() async {
    // Shutter sound
    try {
      await _audioPlayer.play(AssetSource('audio/shutter.mp3'));
    } catch (_) {}

    // Flash effect
    setState(() => _isFlashing = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isFlashing = false);
    });

    // Capture render boundary
    await Future.delayed(const Duration(milliseconds: 50)); // let flash resolve if we wanted, or capture instantly 
    try {
      if (_cameraRowKey.currentContext == null) return;
      final boundary = _cameraRowKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      setState(() {
        _capturedPhotos.add(image);
      });
    } catch (e) {
      debugPrint("Screenshot err: $e");
    }
  }

  Future<void> _savePhotostrip() async {
    if (_capturedPhotos.isEmpty) return;

    if (!kIsWeb) {
      var status = await Permission.storage.request();
      if (!status.isGranted) status = await Permission.photos.request();
    }

    try {
      final int stripWidth = _capturedPhotos[0].width;
      final int photoHeight = _capturedPhotos[0].height;
      final int stripHeight = photoHeight * _capturedPhotos.length;
      
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      final paint = Paint()..color = AppTheme.bg1;
      canvas.drawRect(Rect.fromLTWH(0, 0, stripWidth.toDouble(), stripHeight.toDouble()), paint);
      
      for (int i = 0; i < _capturedPhotos.length; i++) {
        canvas.drawImage(_capturedPhotos[i], Offset(0, (photoHeight * i).toDouble()), Paint());
      }
      
      final finalPicture = recorder.endRecording();
      final finalImage = await finalPicture.toImage(stripWidth, stripHeight);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final fileName = "Photobooth_${DateTime.now().millisecondsSinceEpoch}";
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
              resultPath.isNotEmpty ? 'Photostrip Saved!' : 'Failed to save',
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
  void dispose() {
    _socket.disconnect();
    _localStream?.dispose();
    _remoteStream?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter)) {
          if (widget.room.isHost && _capturedPhotos.length < 4) {
            _triggerSnap();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg1,
        appBar: SharedGameAppBar(
          room: widget.room,
          socket: _socket,
          title: 'Photobooth',
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Photos: ${_capturedPhotos.length} / 4',
                      style: AppTheme.display(24),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 16 / 9, // Wide split screen
                        child: RepaintBoundary(
                          key: _cameraRowKey,
                          child: Container(
                            decoration: AppTheme.velvetCard().copyWith(borderRadius: BorderRadius.zero),
                            clipBehavior: Clip.hardEdge,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Colors.black,
                                    child: RTCVideoView(_localRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                                  ),
                                ),
                                Container(width: 4, color: AppTheme.bg2), // Divider
                                Expanded(
                                  child: Container(
                                    color: Colors.black,
                                    child: _inCalling 
                                      ? RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                                      : const Center(child: CircularProgressIndicator(color: AppTheme.rose)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Film strip preview area
                  Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _capturedPhotos.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.rose, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: RawImage(
                              image: _capturedPhotos[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (widget.room.isHost)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_capturedPhotos.isNotEmpty)
                            AppTheme.roseButton(label: 'Undo', onTap: _triggerUndo, outlined: true),
                          
                          if (_capturedPhotos.length < 4)
                            AppTheme.roseButton(label: 'Snap (Space)', onTap: _triggerSnap),
                            
                          if (_capturedPhotos.length == 4)
                            AppTheme.roseButton(label: 'Download Strip!', onTap: _savePhotostrip),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _capturedPhotos.length == 4 
                          ? 'Waiting for host to save or undo...'
                          : 'Host controls the camera!',
                        style: AppTheme.body(14, color: AppTheme.textSecondary),
                      ),
                    ),
                ],
              ),
              
              // Flash overlay
              if (_isFlashing)
                Positioned.fill(
                  child: Container(color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

