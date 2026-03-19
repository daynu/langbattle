class GamePlayerRecord {
  final String userId;
  final String name;
  final int score;
  final int ratingBefore;
  final int ratingAfter;
  final String? avatarBase64;

  GamePlayerRecord({
    required this.userId,
    required this.name,
    required this.score,
    required this.ratingBefore,
    required this.ratingAfter,
    this.avatarBase64,
  });

  factory GamePlayerRecord.fromJson(Map<String, dynamic> json) {
    return GamePlayerRecord(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      score: (json['score'] as num?)?.toInt() ?? 0,
      ratingBefore: (json['ratingBefore'] as num?)?.toInt() ?? 1000,
      ratingAfter: (json['ratingAfter'] as num?)?.toInt() ?? 1000,
      avatarBase64: json['avatarBase64'] as String?,
    );
  }
}

class GameRecord {
  final String id;
  final List<GamePlayerRecord> players;
  final String language;
  final String level;
  final DateTime playedAt;

  GameRecord({
    required this.id,
    required this.players,
    required this.language,
    required this.level,
    required this.playedAt,
  });

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    final rawPlayers = json['players'] as List? ?? [];
    return GameRecord(
      id: json['id']?.toString() ?? '',
      players: rawPlayers
          .map((p) => GamePlayerRecord.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      language: json['language']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      playedAt: json['playedAt'] != null
          ? DateTime.tryParse(json['playedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  GamePlayerRecord? myRecord(String myUserId) {
    try {
      return players.firstWhere((p) => p.userId == myUserId);
    } catch (_) {
      return null;
    }
  }

  GamePlayerRecord? opponentRecord(String myUserId) {
    try {
      return players.firstWhere((p) => p.userId != myUserId);
    } catch (_) {
      return null;
    }
  }

  bool didWin(String myUserId) {
    final me = myRecord(myUserId);
    final opp = opponentRecord(myUserId);
    if (me == null || opp == null) return false;
    return me.score > opp.score;
  }

  bool isDraw(String myUserId) {
    final me = myRecord(myUserId);
    final opp = opponentRecord(myUserId);
    if (me == null || opp == null) return false;
    return me.score == opp.score;
  }
}