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

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  String? roomId;

  // Getter for socket ID so UI can distinguish players
  String? get socketId => socket?.id;

  /// Connect to the Socket.IO server
  Future<void> connect() async {
    socket = IO.io(
      'http://127.0.0.1:5000',
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


    // 3. Standard Game Events
    socket!.on("match_found", (data) {
      roomId = data["roomId"];
      _controller.add({
        "type": "match_found",
        "roomId": roomId,
        "players": data["players"],
        "questions": data["questions"],
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
            list.add(
              FriendInfo.fromJson(
                Map<String, dynamic>.from(item),
              ),
            );
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
              PlayerSearchResult.fromJson(
                Map<String, dynamic>.from(item),
              ),
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

    socket!.on('friend_removed', (data){
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
      _controller.add({
        "type": "friend_requests",
        "requests": friendRequests,
      });
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
      if (!friendRequests
          .any((r) => r.requestId.toString() == notification.requestId.toString())) {
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
        friendRequests.removeWhere(
          (r) => r.requestId.toString() == requestId,
        );
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

    socket!.onConnect((_) {
      print("Connected to Socket.IO server");
      _restoreAuth();
    });

    socket!.onDisconnect((_) {
      print("Disconnected from server");
    });
  }

  

  void register(String email, String password, String name) {
    socket?.emit("register", {
      "email": email,
      "password": password,
      "name": name,
    });
  }

  void login(String email, String password) {
    socket?.emit("login", {
      "email": email,
      "password": password,
    });
  }

  void sendAnswer(String questionId, dynamic answer) {
    if (socket == null || roomId == null) return;

    socket!.emit("player_event", {
      "roomId": roomId,
      "payload": {
        "action": "answer",
        "questionId": questionId,
        "answer": answer,
        "playerId": currentUser?.userId
      }
    });
  }


  void joinQueue({required String language}) {
  // Wait for authentication first
    if (currentUser == null) {
    print("Waiting for authentication before joining queue...");
    // Listen for auth_success
    StreamSubscription? sub;
    sub = stream.listen((data) {
      if (data["type"] == "auth_success") {
        print("Auth complete, now joining queue");
        socket?.emit("join_queue", {"language": language});
        sub?.cancel();
      }
    });
    return;
    }

  
  // Already authenticated, join immediately
    if ((socket?.connected ?? false)) {
      socket!.emit("join_queue", {"language": language});
      print("Joined matchmaking queue");
    } else {
      print("Cannot join queue: not connected");
    }
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

  // Helper to save data to SharedPreferences and update memory
  Future<void> _saveUserData(Map data) async {
    final prefs = await SharedPreferences.getInstance();

    // Only store token when it's actually present (login/register)
    if (data["token"] != null) {
      await prefs.setString("auth_token", data["token"]);
    }

    // Base rating
    final rawRating = data["rating"];
    final baseRating = rawRating is int
        ? rawRating
        : int.tryParse(rawRating?.toString() ?? "") ?? 1000;

    // Optional per-language ratings from server
    final Map<String, int> ratings = {};
    final rawRatings = data["ratings"];
    if (rawRatings is Map) {
      rawRatings.forEach((key, value) {
        if (value is int) {
          ratings[key.toString()] = value;
        } else {
          final parsed = int.tryParse(value.toString());
          if (parsed != null) ratings[key.toString()] = parsed;
        }
      });
    }

    // If none provided, default all languages to base rating
    if (ratings.isEmpty) {
      ratings["english"] = baseRating;
      ratings["german"] = baseRating;
      ratings["french"] = baseRating;
    }

    final rawFriendsCount = data["friendsCount"];
    final friendsCount = rawFriendsCount is int
        ? rawFriendsCount
        : int.tryParse(rawFriendsCount?.toString() ?? "") ?? 0;

    currentUser = UserSession(
      userId: data["userId"].toString(),
      name: data["name"] ?? "",
      rating: baseRating,
      ratings: ratings,
      friendsCount: friendsCount,
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

  void sendFinish() {
    socket?.emit("player_event", {
      "roomId": roomId,
      "payload": {
        "action": "finish",
        "playerId": currentUser?.userId,
      }
    });
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    currentUser = null;
    friends = [];
    searchResults = [];
    friendRequests = [];
    _controller.add({"type": "logged_out"});
    disconnect();
  }
}


class UserSession {
  final String userId;
  final String name;
  final int rating;
  final Map<String, int> ratings;
   final int friendsCount;

  UserSession({
    required this.userId,
    required this.name,
    required this.rating,
    required this.ratings,
    this.friendsCount = 0,
  });

  int ratingForLanguage(String languageKey) {
    final key = languageKey.toLowerCase();
    return ratings[key] ?? rating;
  }

  // Factory needed for restoring from SharedPreferences
  factory UserSession.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'];
    final baseRating = rawRating is int
        ? rawRating
        : int.tryParse(rawRating?.toString() ?? "") ?? 1000;

    final Map<String, int> ratings = {};
    final rawRatings = json['ratings'];
    if (rawRatings is Map) {
      rawRatings.forEach((key, value) {
        if (value is int) {
          ratings[key.toString()] = value;
        } else {
          final parsed = int.tryParse(value.toString());
          if (parsed != null) ratings[key.toString()] = parsed;
        }
      });
    }
    if (ratings.isEmpty) {
      ratings["english"] = baseRating;
      ratings["german"] = baseRating;
      ratings["french"] = baseRating;
    }

    final rawFriendsCount = json['friendsCount'];
    final friendsCount = rawFriendsCount is int
        ? rawFriendsCount
        : int.tryParse(rawFriendsCount?.toString() ?? "") ?? 0;

    return UserSession(
      userId: json['userId'].toString(),
      name: json['name'] ?? 'Unknown',
      rating: baseRating,
      ratings: ratings,
      friendsCount: friendsCount,
    );
  }

  UserSession copyWith({
    String? name,
    int? rating,
    Map<String, int>? ratings,
    int? friendsCount,
  }) {
    return UserSession(
      userId: userId,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      ratings: ratings ?? this.ratings,
      friendsCount: friendsCount ?? this.friendsCount,
    );
  }
}

class FriendInfo {
  final String userId;
  final String name;
  final int rating;

  FriendInfo({
    required this.userId,
    required this.name,
    required this.rating,
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
