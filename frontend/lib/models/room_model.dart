class RoomModel {
  final String roomId;
  final String code;
  final String role; // "HOST" or "GUEST"
  final String? hostName;
  final String? guestName;

  RoomModel({
    required this.roomId,
    required this.code,
    required this.role,
    this.hostName,
    this.guestName,
  });

  bool get isHost => role == 'HOST';

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      roomId: map['roomId'] ?? '',
      code: map['code'] ?? '',
      role: map['role'] ?? 'GUEST',
      hostName: map['hostName'],
      guestName: map['guestName'],
    );
  }
}
