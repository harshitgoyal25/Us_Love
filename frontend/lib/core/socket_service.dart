import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'config.dart';
import 'app_error.dart';
import 'error_service.dart';

class SocketService {
  StompClient? _client;
  String? currentRoomId;

  void connect({
    required String roomId,
    required String token,
    required Function(Map<String, dynamic>) onMessage,
    required Function() onConnected,
  }) {
    currentRoomId = roomId;
    _client = StompClient(
      config: StompConfig(
        url: '${AppConfig.wsBase}/ws',
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
        onConnect: (frame) {
          onConnected();
          _client!.subscribe(
            destination: '/topic/room/$roomId',
            callback: (frame) {
              if (frame.body != null) {
                onMessage(_parseMessage(frame.body!));
              }
            },
          );
        },
        onDisconnect: (frame) {
          print('Disconnected');
          // Optional: Show error if disconnect was unexpected
        },
        onStompError: (frame) {
          print('STOMP error: ${frame.body}');
          ErrorService.instance.showError(AppError.server('Game synchronization error.'));
        },
        onWebSocketError: (error) {
          print('WS error: $error');
          ErrorService.instance.showError(AppError.socket());
        },
      ),
    );
    _client!.activate();
  }

  void sendEvent(String roomId, Map<String, dynamic> event) {
    _client?.send(
      destination: '/app/room/$roomId',
      body: _toJson(event),
    );
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    currentRoomId = null;
  }

  Map<String, dynamic> _parseMessage(String body) {
    return jsonDecode(body) as Map<String, dynamic>;
  }

  String _toJson(Map<String, dynamic> map) => jsonEncode(map);
}