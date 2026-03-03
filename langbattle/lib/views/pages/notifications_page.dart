import 'dart:async';

import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';

class NotificationsPage extends StatefulWidget {
  final BattleService battleService;

  const NotificationsPage({
    super.key,
    required this.battleService,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.battleService.stream.listen((event) {
      final type = event["type"];
      if (!mounted) return;
      if (type == "friend_requests" ||
          type == "friend_request_created" ||
          type == "friend_request_updated" ||
          type == "friend_added") {
        setState(() {});
      }
      if (type == "error") {
        final message = event["message"]?.toString() ?? "Something went wrong";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });

    widget.battleService.requestFriendRequests();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requests = widget.battleService.friendRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: requests.isEmpty
          ? const Center(
              child: Text(
                'No notifications at the moment.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final req = requests[index];
                final subtitle = StringBuffer()
                  ..write('Rating: ${req.fromRating}');
                if (req.createdAt != null) {
                  subtitle.write(
                      ' • ${req.createdAt!.toLocal().toString().split(".").first}');
                }

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text('${req.fromName} wants to add you as a friend'),
                  subtitle: Text(subtitle.toString()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          widget.battleService.respondToFriendRequest(
                            req.requestId,
                            accept: false,
                          );
                        },
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          widget.battleService.respondToFriendRequest(
                            req.requestId,
                            accept: true,
                          );
                        },
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

