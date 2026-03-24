class RoomModel {
  final String roomId;
  final String code;
  final String role; // "HOST" or "GUEST"

  RoomModel({
    required this.roomId,
    required this.code,
    required this.role,
  });

  bool get isHost => role == 'HOST';

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      roomId: map['roomId'] ?? '',
      code: map['code'] ?? '',
      role: map['role'] ?? 'GUEST',
    );
  }
}