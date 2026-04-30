import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
// import 'dart:convert'; // Required for jsonDecode

class BattleService {
  IO.Socket? socket;
  UserSession? currentUser;
  List<FriendInfo> friends = [];
  List<PlayerSearchResult> searchResults = [];
  List<FriendRequestNotification> friendRequests = [];
  List<ChallengeNotification> challenges = [];
  Map<String, dynamic>? activeRoom;
  int onlineCount = 0;
  final Map<String, Completer<PlayerPublicProfile>> _profileRequests = {};

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  String? roomId;

  // Getter for socket ID so UI can distinguish players
  String? get socketId => socket?.id;

  /// Connect to the Socket.IO server
  Future<void> connect() async {
    socket = IO.io(
      'http://localhost:3000', // Change to your server URL
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket!.on("auth_success", (data) {
      print("Authentication restored/verified");
      _saveUserData(data); // Update local storage

      // Notify UI that auth is ready
      _controller.add({"type": "auth_success", "data": data});
    });

    socket!.on("auth_failed", (_) {
      _controller.add({"type": "auth_failed"});
    });

    socket!.on("rating_history", (data) {
      _controller.add({
        "type": "rating_history",
        "language": data["language"],
        "history": data["history"] ?? [],
      });
    });

    socket!.on("online_count", (data) {
      onlineCount = data["count"] ?? 0;
      print("Online count received : $onlineCount");
      _controller.add({"type": "online_count"});
    });

    socket!.on("active_room", (data) {
      activeRoom = data["room"]; // save it
      _controller.add({"type": "active_room", "room": data["room"]});
    });

    socket!.on("room_expired", (_) {
      _controller.add({"type": "room_expired"});
    });

    socket!.on("opponent_reconnected", (_) {
      _controller.add({"type": "opponent_reconnected"});
    });

    socket!.on("game_history", (data) {
      _controller.add({"type": "game_history", "games": data["games"] ?? []});
    });

    // 3. Standard Game Events
    socket!.on("match_found", (data) {
      roomId = data["roomId"];
      _controller.add({
        "type": "match_found",
        "roomId": roomId,
        "mode": data["mode"],
        "language": data["language"],
        "players": data["players"],
        "questions": data["questions"],
        "startWord": data["startWord"],
        "usedWords": data["usedWords"] ?? const [],
        "durationSeconds": data["durationSeconds"],
        "endsAt": data["endsAt"],
        "challenge": data["challenge"] == true,
      });
    });

    socket!.on("player_event", (payload) {
      _controller.add({"type": "player_event", "payload": payload});
    });

    socket!.on("opponent_disconnected", (_) {
      _controller.add({"type": "opponent_disconnected"});
    });

    socket!.on("register_success", (data) {
      _saveUserData(data);
      _controller.add({"type": "auth_success", "data": data});
    });

    socket!.on("login_success", (data) {
      _saveUserData(data);
      _controller.add({"type": "auth_success", "data": data});
    });

    socket!.on("friends_list", (data) {
      final rawList = data["friends"];
      final list = <FriendInfo>[];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map) {
            list.add(FriendInfo.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      friends = list;
      final count = data["friendsCount"];
      if (currentUser != null && count is int) {
        currentUser = currentUser!.copyWith(friendsCount: count);
      }
      _controller.add({
        "type": "friends_list",
        "friends": friends,
        "friendsCount": count,
      });
    });

    socket!.on("friend_added", (data) {
      final rawFriend = data["friend"];
      if (rawFriend is Map) {
        final friend = FriendInfo.fromJson(
          Map<String, dynamic>.from(rawFriend),
        );
        if (!friends.any((f) => f.userId == friend.userId)) {
          friends.add(friend);
        }
      }
      final count = data["friendsCount"];
      if (currentUser != null && count is int) {
        currentUser = currentUser!.copyWith(friendsCount: count);
      }
      _controller.add({
        "type": "friend_added",
        "friend": friends.isNotEmpty ? friends.last : null,
        "friendsCount": count,
      });
    });

    socket!.on("search_players_result", (data) {
      final rawList = data["players"];
      final list = <PlayerSearchResult>[];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map) {
            list.add(
              PlayerSearchResult.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }
      searchResults = list;
      _controller.add({
        "type": "search_players_result",
        "players": searchResults,
        "query": data["query"],
      });
    });

    socket!.on('friend_removed', (data) {
      requestFriendsList();
    });

    socket!.on("friend_requests", (data) {
      final rawList = data["requests"];
      final list = <FriendRequestNotification>[];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map) {
            list.add(
              FriendRequestNotification.fromJson(
                Map<String, dynamic>.from(item),
              ),
            );
          }
        }
      }
      friendRequests = list;
      _controller.add({"type": "friend_requests", "requests": friendRequests});
    });

    socket!.on("friend_request_created", (data) {
      final notification = FriendRequestNotification.fromJson(
        Map<String, dynamic>.from(data),
      );
      final currentId = currentUser?.userId;
      if (currentId != null &&
          notification.toUserId.toString() != currentId.toString()) {
        // Not for this user; ignore
        return;
      }
      if (!friendRequests.any(
        (r) => r.requestId.toString() == notification.requestId.toString(),
      )) {
        friendRequests.insert(0, notification);
      }
      _controller.add({
        "type": "friend_request_created",
        "request": notification,
        "requests": friendRequests,
      });
    });

    socket!.on("friend_request_updated", (data) {
      final requestId = data["requestId"]?.toString();
      final toUserId = data["toUserId"]?.toString();
      final currentId = currentUser?.userId;
      if (currentId != null && toUserId != null && toUserId != currentId) {
        // For now, only update list for the recipient; sender gets a toast via UI if desired.
        return;
      }
      if (requestId != null) {
        friendRequests.removeWhere((r) => r.requestId.toString() == requestId);
      }
      _controller.add({
        "type": "friend_request_updated",
        "requestId": requestId,
        "requests": friendRequests,
        "status": data["status"]?.toString(),
      });
    });

    socket!.on("error_msg", (msg) {
      _controller.add({"type": "error", "message": msg});
    });

    socket!.on("player_profile", (data) {
      final profile = PlayerPublicProfile.fromJson(
        Map<String, dynamic>.from(data),
      );
      _profileRequests.remove(profile.userId)?.complete(profile);
      _controller.add({"type": "player_profile", "profile": profile});
    });

    socket!.on("player_profile_error", (data) {
      final userId = data["userId"]?.toString() ?? "";
      final message = data["message"]?.toString() ?? "Could not load player";
      _profileRequests.remove(userId)?.completeError(Exception(message));
      _controller.add({"type": "error", "message": message});
    });

    socket!.on("challenge_sent", (data) {
      _controller.add({
        "type": "challenge_sent",
        "userId": data["userId"],
        "mode": data["mode"],
        "language": data["language"],
      });
    });

    socket!.on("challenge_received", (data) {
      final challenge = ChallengeNotification.fromJson(
        Map<String, dynamic>.from(data),
      );
      challenges.removeWhere((c) => c.challengeId == challenge.challengeId);
      challenges.insert(0, challenge);
      _controller.add({
        "type": "challenge_received",
        "challenge": challenge,
        "challenges": challenges,
        "fromUserId": data["fromUserId"],
        "fromName": data["fromName"],
        "mode": data["mode"],
        "language": data["language"],
      });
    });

    socket!.on("player_reported", (data) {
      _controller.add({"type": "player_reported", "userId": data["userId"]});
    });

    socket!.on("challenge_declined", (data) {
      final challengeId = data["challengeId"]?.toString();
      if (challengeId != null) {
        challenges.removeWhere((c) => c.challengeId == challengeId);
      }
      _controller.add({
        "type": "challenge_declined",
        "challengeId": challengeId,
        "challenges": challenges,
      });
    });

    socket!.on("challenge_expired", (data) {
      final challengeId = data["challengeId"]?.toString();
      if (challengeId != null) {
        challenges.removeWhere((c) => c.challengeId == challengeId);
      }
      _controller.add({
        "type": "challenge_expired",
        "challengeId": challengeId,
        "challenges": challenges,
      });
    });

    socket!.on("rating_updated", (data) {
      final language = data["language"]?.toString();
      final newRating = data["newRating"];
      final parsedRating = newRating is int
          ? newRating
          : int.tryParse(newRating?.toString() ?? "");
      final rawWinStreak = data["winStreak"];
      final parsedWinStreak = rawWinStreak is int
          ? rawWinStreak
          : int.tryParse(rawWinStreak?.toString() ?? "");

      if (currentUser != null) {
        // Update the in-memory ratings map
        final updatedRatings = Map<String, int?>.from(currentUser!.ratings);
        if (language != null && parsedRating != null) {
          updatedRatings[language] = parsedRating;
        }
        currentUser = currentUser!.copyWith(
          ratings: updatedRatings,
          winStreak: parsedWinStreak,
        );
      }

      _controller.add({
        "type": "rating_updated",
        "language": language,
        "newRating": parsedRating,
        "oldRating": data["oldRating"],
        "delta": data["delta"],
        "newLevel": data["newLevel"],
        "winStreak": parsedWinStreak,
      });
    });

    socket!.onConnect((_) {
      print("Connected to Socket.IO server");
      _restoreAuth();
    });

    socket!.on("avatar_updated", (data) {
      final base64 = data["avatarBase64"]?.toString();
      if (base64 != null && currentUser != null) {
        currentUser = currentUser!.copyWith(avatarBase64: base64);
      }
      _controller.add({"type": "avatar_updated", "avatarBase64": base64});
    });

    socket!.onDisconnect((_) {
      print("Disconnected from server");
    });
  }

  void register(
    String email,
    String password,
    String name, {
    required String language,
    required int startingRating,
  }) {
    socket?.emit("register", {
      "email": email,
      "password": password,
      "name": name,
      "language": language,
      "startingRating": startingRating,
    });
  }

  void login(String email, String password) {
    socket?.emit("login", {"email": email, "password": password});
  }

  void sendAnswer(String questionId, dynamic answer) {
    if (socket == null || roomId == null) return;

    socket!.emit("player_event", {
      "roomId": roomId,
      "payload": {
        "action": "answer",
        "questionId": questionId,
        "answer": answer,
        "playerId": currentUser?.userId,
      },
    });
  }

  void uploadAvatar(String base64Image) {
    socket?.emit("upload_avatar", {"base64Image": base64Image});
  }

  void joinQueue({required String language, required String mode}) {
    // Wait for authentication first
    if (currentUser == null) {
      print("Waiting for authentication before joining queue...");
      // Listen for auth_success
      StreamSubscription? sub;
      sub = stream.listen((data) {
        if (data["type"] == "auth_success") {
          print("Auth complete, now joining queue");
          socket?.emit("join_queue", {"language": language, "mode": mode});
          sub?.cancel();
        }
      });
      return;
    }

    // Already authenticated, join immediately
    if ((socket?.connected ?? false)) {
      socket!.emit("join_queue", {"language": language, "mode": mode});
      print("Joined matchmaking queue");
    } else {
      print("Cannot join queue: not connected");
    }
  }

  void submitWordChainWord(String word) {
    final trimmed = word.trim();
    if (socket == null || roomId == null || trimmed.isEmpty) return;

    socket!.emit("player_event", {
      "roomId": roomId,
      "payload": {
        "action": "word_chain_move",
        "word": trimmed,
        "playerId": currentUser?.userId,
      },
    });
  }

  void addFriendByEmail(String email) {
    if (socket == null || email.isEmpty) return;
    socket!.emit("add_friend", {"email": email});
  }

  void addFriendById(String userId) {
    if (socket == null || userId.isEmpty) return;
    socket!.emit("add_friend", {"userId": userId});
  }

  void removeFriend(String userId) {
    if (socket == null || userId.isEmpty) return;
    socket!.emit("remove_friend", {"userId": userId});
  }

  void requestFriendsList() {
    if (socket == null) return;
    socket!.emit("get_friends");
  }

  void requestRatingHistory(String language) {
    socket?.emit("get_rating_history", {"language": language});
  }

  void searchPlayersByName(String name) {
    if (socket == null) return;
    final query = name.trim();
    if (query.isEmpty) {
      searchResults = [];
      _controller.add({
        "type": "search_players_result",
        "players": searchResults,
        "query": "",
      });
      return;
    }
    socket!.emit("search_players", {"name": query});
  }

  void requestFriendRequests() {
    if (socket == null) return;
    socket!.emit("get_friend_requests");
  }

  void respondToFriendRequest(String requestId, {required bool accept}) {
    if (socket == null || requestId.isEmpty) return;
    final action = accept ? "accept" : "reject";
    socket!.emit("respond_friend_request", {
      "requestId": requestId,
      "action": action,
    });
  }

  void requestActiveRoom() {
    socket?.emit("get_active_room");
  }

  Future<PlayerPublicProfile> requestPlayerProfile(String userId) {
    final existing = _profileRequests[userId];
    if (existing != null) return existing.future;

    final completer = Completer<PlayerPublicProfile>();
    _profileRequests[userId] = completer;
    socket?.emit("get_player_profile", {"userId": userId});

    Future.delayed(const Duration(seconds: 8), () {
      final pending = _profileRequests.remove(userId);
      if (pending != null && !pending.isCompleted) {
        pending.completeError(Exception("Could not load player profile"));
      }
    });

    return completer.future;
  }

  void challengePlayer(
    String userId, {
    required String mode,
    required String language,
  }) {
    socket?.emit("challenge_player", {
      "userId": userId,
      "mode": mode,
      "language": language,
    });
  }

  void reportPlayer(String userId, String reason) {
    socket?.emit("report_player", {"userId": userId, "reason": reason});
  }

  void respondToChallenge(String challengeId, {required bool accept}) {
    challenges.removeWhere((c) => c.challengeId == challengeId);
    _controller.add({"type": "challenge_updated", "challenges": challenges});
    socket?.emit("respond_challenge", {
      "challengeId": challengeId,
      "accept": accept,
    });
  }

  void rejoinRoom(String roomId) {
    this.roomId = roomId;
    socket?.emit("rejoin_room", {"roomId": roomId});
  }

  // Helper to save data to SharedPreferences and update memory
  Future<void> _saveUserData(Map data) async {
    final prefs = await SharedPreferences.getInstance();

    if (data["token"] != null) {
      await prefs.setString("auth_token", data["token"]);
    }

    final rawRating = data["rating"];
    final baseRating = rawRating is int
        ? rawRating
        : int.tryParse(rawRating?.toString() ?? "") ?? 1000;

    final Map<String, int?> ratings = {};
    final rawRatings = data["ratings"];
    if (rawRatings is Map) {
      rawRatings.forEach((key, value) {
        if (value == null) {
          ratings[key.toString()] = null;
        } else if (value is int) {
          ratings[key.toString()] = value;
        } else {
          final parsed = int.tryParse(value.toString());
          ratings[key.toString()] = parsed;
        }
      });
    }
    if (ratings.isEmpty) {
      ratings["english"] = baseRating;
      ratings["german"] = baseRating;
      ratings["french"] = baseRating;
    }

    final rawFriendsCount = data["friendsCount"];
    final friendsCount = rawFriendsCount is int
        ? rawFriendsCount
        : int.tryParse(rawFriendsCount?.toString() ?? "") ?? 0;
    final rawWinStreak = data["winStreak"];
    final winStreak = rawWinStreak is int
        ? rawWinStreak
        : int.tryParse(rawWinStreak?.toString() ?? "") ?? 0;

    DateTime? createdAt;
    final rawCreatedAt = data["createdAt"];
    if (rawCreatedAt is String) createdAt = DateTime.tryParse(rawCreatedAt);

    DateTime? lastSeen;
    final rawLastSeen = data["lastSeen"];
    if (rawLastSeen is String) lastSeen = DateTime.tryParse(rawLastSeen);

    currentUser = UserSession(
      userId: data["userId"].toString(),
      name: data["name"] ?? "",
      rating: baseRating,
      ratings: ratings,
      friendsCount: friendsCount,
      winStreak: winStreak,
      createdAt: createdAt,
      lastSeen: lastSeen,
      avatarBase64: data["avatarBase64"]?.toString(),
    );
  }

  // Restores Auth on Reload
  Future<void> _restoreAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    if (token != null) {
      print("Attempting to restore session with token...");
      socket?.emit("auth", {"token": token});
    }
  }

  void disconnect() {
    if (socket != null) {
      socket!.disconnect();
      socket!.destroy(); // Clean up socket listeners
      socket = null;
    }

    if (!_controller.isClosed) {
      _controller.close();
    }
    print("Socket disconnected and resources cleaned up.");
  }

  void leaveQueue() {
    if (socket == null) return;
    socket!.emit("leave_queue");
  }

  void sendFinish({int score = 0}) {
    socket?.emit("player_event", {
      "roomId": roomId,
      "payload": {
        "action": "finish",
        "playerId": currentUser?.userId,
        "score": score,
      },
    });
  }

  void requestGameHistory() {
    socket?.emit("get_game_history");
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    currentUser = null;
    friends = [];
    searchResults = [];
    friendRequests = [];
    challenges = [];
    _controller.add({"type": "logged_out"});
    disconnect();
  }
}

class PlayerPublicProfile {
  final String userId;
  final String name;
  final String? avatarBase64;
  final DateTime? createdAt;
  final String bestLanguage;
  final int bestRating;
  final String bestRank;

  PlayerPublicProfile({
    required this.userId,
    required this.name,
    this.avatarBase64,
    this.createdAt,
    required this.bestLanguage,
    required this.bestRating,
    required this.bestRank,
  });

  factory PlayerPublicProfile.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json["createdAt"];
    DateTime? createdAt;
    if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    } else if (rawCreatedAt is Map) {
      createdAt = DateTime.tryParse(rawCreatedAt["\$date"]?.toString() ?? "");
    }

    final rawBestRating = json["bestRating"];
    final bestRating = rawBestRating is int
        ? rawBestRating
        : int.tryParse(rawBestRating?.toString() ?? "") ?? 0;

    return PlayerPublicProfile(
      userId: json["userId"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "Unknown",
      avatarBase64: json["avatarBase64"]?.toString(),
      createdAt: createdAt,
      bestLanguage: json["bestLanguage"]?.toString() ?? "english",
      bestRating: bestRating,
      bestRank: json["bestRank"]?.toString() ?? "",
    );
  }
}

class ChallengeNotification {
  final String challengeId;
  final String fromUserId;
  final String fromName;
  final String mode;
  final String language;
  final DateTime createdAt;

  ChallengeNotification({
    required this.challengeId,
    required this.fromUserId,
    required this.fromName,
    required this.mode,
    required this.language,
    required this.createdAt,
  });

  factory ChallengeNotification.fromJson(Map<String, dynamic> json) {
    return ChallengeNotification(
      challengeId: json["challengeId"]?.toString() ?? "",
      fromUserId: json["fromUserId"]?.toString() ?? "",
      fromName: json["fromName"]?.toString() ?? "Unknown",
      mode: json["mode"]?.toString() ?? "classic",
      language: json["language"]?.toString() ?? "english",
      createdAt: DateTime.now(),
    );
  }
}

class UserSession {
  final String userId;
  final String name;
  final int rating;
  final Map<String, int?> ratings;
  final int friendsCount;
  final int winStreak;
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final String? avatarBase64;

  UserSession({
    required this.userId,
    required this.name,
    required this.rating,
    required this.ratings,
    this.friendsCount = 0,
    this.winStreak = 0,
    this.createdAt,
    this.lastSeen,
    this.avatarBase64,
  });

  int? ratingForLanguage(String languageKey) {
    final key = languageKey.toLowerCase();
    return ratings[key];
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'];
    final baseRating = rawRating is int
        ? rawRating
        : int.tryParse(rawRating?.toString() ?? '') ?? 1000;

    final Map<String, int?> ratings = {};
    final rawRatings = json['ratings'];
    if (rawRatings is Map) {
      rawRatings.forEach((key, value) {
        if (value == null) {
          ratings[key.toString()] = null;
        } else if (value is int) {
          ratings[key.toString()] = value;
        } else {
          final parsed = int.tryParse(value.toString());
          ratings[key.toString()] = parsed;
        }
      });
    }
    if (ratings.isEmpty) {
      ratings['english'] = baseRating;
      ratings['german'] = baseRating;
      ratings['french'] = baseRating;
    }

    final rawFriendsCount = json['friendsCount'];
    final friendsCount = rawFriendsCount is int
        ? rawFriendsCount
        : int.tryParse(rawFriendsCount?.toString() ?? '') ?? 0;
    final rawWinStreak = json['winStreak'];
    final winStreak = rawWinStreak is int
        ? rawWinStreak
        : int.tryParse(rawWinStreak?.toString() ?? '') ?? 0;

    DateTime? createdAt;
    final rawCreatedAt = json['createdAt'];
    if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    } else if (rawCreatedAt is Map) {
      // MongoDB date objects sometimes come as { $date: "..." }
      createdAt = DateTime.tryParse(rawCreatedAt['\$date']?.toString() ?? '');
    }

    DateTime? lastSeen;
    final rawLastSeen = json['lastSeen'];
    if (rawLastSeen is String) {
      lastSeen = DateTime.tryParse(rawLastSeen);
    } else if (rawLastSeen is Map) {
      lastSeen = DateTime.tryParse(rawLastSeen['\$date']?.toString() ?? '');
    }

    return UserSession(
      userId: json['userId'].toString(),
      name: json['name'] ?? 'Unknown',
      rating: baseRating,
      ratings: ratings,
      friendsCount: friendsCount,
      winStreak: winStreak,
      createdAt: createdAt,
      lastSeen: lastSeen,
      avatarBase64: json['avatarBase64']?.toString(),
    );
  }

  UserSession copyWith({
    String? name,
    int? rating,
    Map<String, int?>? ratings,
    int? friendsCount,
    int? winStreak,
    DateTime? createdAt,
    DateTime? lastSeen,
    String? avatarBase64,
  }) {
    return UserSession(
      userId: userId,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      ratings: ratings ?? this.ratings,
      friendsCount: friendsCount ?? this.friendsCount,
      winStreak: winStreak ?? this.winStreak,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
    );
  }
}

class FriendInfo {
  final String userId;
  final String name;
  final int rating;
  final String? avatarBase64;
  final bool isOnline;

  FriendInfo({
    required this.userId,
    required this.name,
    required this.rating,
    this.avatarBase64,
    this.isOnline = false,
  });

  factory FriendInfo.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'];
    final rating = rawRating is int
        ? rawRating
        : int.tryParse(rawRating?.toString() ?? "") ?? 0;

    return FriendInfo(
      userId: json['userId'].toString(),
      name: json['name'] ?? 'Unknown',
      rating: rating,
      avatarBase64: json['avatarBase64'] as String?,
      isOnline: json['isOnline'] == true,
    );
  }
}

class PlayerSearchResult {
  final String userId;
  final String name;
  final int rating;
  final bool isFriend;
  final bool isSelf;

  PlayerSearchResult({
    required this.userId,
    required this.name,
    required this.rating,
    required this.isFriend,
    required this.isSelf,
  });

  factory PlayerSearchResult.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'];
    final rating = rawRating is int
        ? rawRating
        : int.tryParse(rawRating?.toString() ?? "") ?? 0;

    return PlayerSearchResult(
      userId: json['userId'].toString(),
      name: json['name'] ?? 'Unknown',
      rating: rating,
      isFriend: json['isFriend'] == true,
      isSelf: json['isSelf'] == true,
    );
  }
}

class FriendRequestNotification {
  final String requestId;
  final String fromUserId;
  final String toUserId;
  final String fromName;
  final int fromRating;
  final String status;
  final DateTime? createdAt;

  FriendRequestNotification({
    required this.requestId,
    required this.fromUserId,
    required this.toUserId,
    required this.fromName,
    required this.fromRating,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestNotification.fromJson(Map<String, dynamic> json) {
    final rawRating = json['fromRating'];
    final rating = rawRating is int
        ? rawRating
        : int.tryParse(rawRating?.toString() ?? "") ?? 0;

    DateTime? created;
    final rawCreated = json['createdAt'];
    if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated);
    }

    return FriendRequestNotification(
      requestId: json['requestId']?.toString() ?? '',
      fromUserId: json['fromUserId']?.toString() ?? '',
      toUserId: json['toUserId']?.toString() ?? '',
      fromName: json['fromName']?.toString() ?? 'Unknown',
      fromRating: rating,
      status: json['status']?.toString() ?? 'pending',
      createdAt: created,
    );
  }
}
