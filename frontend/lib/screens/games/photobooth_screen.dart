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
      if (mounted) setState(() {});
      _createPeerConnection();
      
      // Tell the other user that we are ready to receive or create offers
      _socket.sendEvent(widget.room.roomId, {
        'type': 'GAME_ACTION',
        'payload': {
          'action': 'WEBRTC_READY',
          'userId': _myId,
        }
      });
      
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
      if (mounted) {
        setState(() {
          _inCalling = true;
        });
      }
    };

    _localStream?.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    if (widget.room.isHost) {
      _createOffer();
    }
  }

  Future<void> _createOffer() async {
    if (_peerConnection == null) return;
    try {
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
    // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> _createAnswer() async {
    if (_peerConnection == null) return;
    try {
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
    // ignore: empty_catches
    } catch (e) {}
  }

  void _onSignalingMessage(dynamic event) async {
    if (event['type'] == 'GAME_STATE_UPDATE') {
      final payload = event['payload'];
      if (payload == null) return;
      
      final action = payload['action'];
      final senderId = payload['userId'];
      
      if (senderId == _myId && senderId != null) return; // ignore self
      
      if (action == 'WEBRTC_READY') {
         // If a user becomes ready and we are the host, recreate/send the offer
         if (widget.room.isHost) {
            _createOffer();
         }
      } else if (action == 'WEBRTC_OFFER') {
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
        if (mounted) {
          setState(() {
            if (_capturedPhotos.isNotEmpty) _capturedPhotos.removeLast();
          });
        }
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
    if (mounted) {
      setState(() {
        _capturedPhotos.removeLast();
      });
    }
  }

  Future<void> _snapLocalPhoto() async {
    // Shutter sound
    try {
      await _audioPlayer.play(AssetSource('audio/shutter.mp3'));
    // ignore: empty_catches
    } catch (_) {}

    // Flash effect
    if (mounted) setState(() => _isFlashing = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isFlashing = false);
    });

    // Capture render boundary
    await Future.delayed(const Duration(milliseconds: 50)); 
    try {
      if (_cameraRowKey.currentContext == null) return;
      final boundary = _cameraRowKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      if (mounted) {
        setState(() {
          _capturedPhotos.add(image);
        });
      }
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
      
      // Add a border size for styling
      const int borderSize = 20; 
      
      final int finalWidth = stripWidth + (borderSize * 2);
      final int finalHeight = (photoHeight * _capturedPhotos.length) + (borderSize * (_capturedPhotos.length + 1));
      
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      final paint = Paint()..color = AppTheme.bg1;
      canvas.drawRect(Rect.fromLTWH(0, 0, finalWidth.toDouble(), finalHeight.toDouble()), paint);
      
      int currentY = borderSize;
      for (int i = 0; i < _capturedPhotos.length; i++) {
        canvas.drawImage(_capturedPhotos[i], Offset(borderSize.toDouble(), currentY.toDouble()), Paint());
        currentY += photoHeight + borderSize;
      }
      
      final finalPicture = recorder.endRecording();
      final finalImage = await finalPicture.toImage(finalWidth, finalHeight);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final fileName = "Us_Love_Photobooth_${DateTime.now().millisecondsSinceEpoch}";
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

  void _backToLobby() {
    _socket.sendEvent(widget.room.roomId, {
       'type': 'BACK_TO_LOBBY',
       'payload': {}
    });
    context.go('/lobby', extra: widget.room);
  }

  @override
  void dispose() {
    _socket.disconnect();
    
    // Explicitly turn off hardware camera/mic tracks!
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        track.stop();
      }
    }

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
    
    // 1. Result/Preview State (When 4 photos are captured)
    if (_capturedPhotos.length == 4) {
      return Scaffold(
        backgroundColor: AppTheme.bg1,
        appBar: SharedGameAppBar(
          room: widget.room,
          socket: _socket,
          title: 'Your Photostrip!',
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                 child: Center(
                   child: SingleChildScrollView(
                     padding: const EdgeInsets.symmetric(vertical: 24),
                     child: Container(
                       width: 240,
                       decoration: BoxDecoration(
                         color: AppTheme.bg2,
                         border: Border.all(color: AppTheme.rose, width: 4),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       padding: const EdgeInsets.all(12),
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: List.generate(4, (i) => Padding(
                           padding: EdgeInsets.only(bottom: i < 3 ? 12 : 0),
                           child: ClipRRect(
                             borderRadius: BorderRadius.circular(8),
                             child: RawImage(image: _capturedPhotos[i], fit: BoxFit.cover, width: double.infinity),
                           ),
                         )),
                       )
                     )
                   )
                 )
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                     AppTheme.roseButton(label: 'Download Strip', onTap: _savePhotostrip),
                     if (widget.room.isHost)
                       AppTheme.roseButton(label: 'Back to Lobby', outlined: true, onTap: _backToLobby),
                  ],
                ),
              ),
              if (!widget.room.isHost)
                 Padding(
                   padding: const EdgeInsets.only(bottom: 24.0),
                   child: Text("Waiting for host to return to the Lobby...", style: AppTheme.body(14, color: AppTheme.textSecondary)),
                 )
            ]
          )
        )
      );
    }

    // 2. Live Capture State
    return Scaffold(
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
                
                // Film strip mini-preview area
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
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Space reserved for balance if undo is hidden
                        if (_capturedPhotos.isEmpty) const SizedBox(width: 48, height: 48),
                        if (_capturedPhotos.isNotEmpty)
                           InkWell(
                              onTap: _triggerUndo,
                              customBorder: const CircleBorder(),
                              child: const CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.bg2,
                                child: Icon(Icons.undo, color: AppTheme.rose),
                              ),
                           ),
                        const SizedBox(width: 48),

                        // Big Capture Button
                        InkWell(
                          onTap: _triggerSnap,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               border: Border.all(color: AppTheme.rose.withOpacity(0.5), width: 6),
                            ),
                            child: Container(
                               margin: const EdgeInsets.all(4),
                               decoration: const BoxDecoration(
                                 shape: BoxShape.circle,
                                 color: AppTheme.rose,
                               ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                        
                        // Balance empty space to keep button centered
                        const SizedBox(width: 48, height: 48),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Host controls the camera!',
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
    );
  }
}
