class GameEvent {
  final String type;
  final String? game;
  final Map<String, dynamic>? payload;

  GameEvent({
    required this.type,
    this.game,
    this.payload,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      if (game != null) 'game': game,
      if (payload != null) ...payload!,
    };
  }

  factory GameEvent.fromMap(Map<String, dynamic> map) {
    return GameEvent(
      type: map['type'] ?? '',
      game: map['game'],
      payload: map,
    );
  }
}