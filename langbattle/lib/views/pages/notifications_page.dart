import 'dart:async';

import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';

class NotificationsPage extends StatefulWidget {
  final BattleService battleService;

  const NotificationsPage({super.key, required this.battleService});

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
          type == "friend_added" ||
          type == "challenge_received" ||
          type == "challenge_updated" ||
          type == "challenge_declined" ||
          type == "challenge_expired") {
        setState(() {});
      }
      if (type == "error") {
        final message = event["message"]?.toString() ?? "Something went wrong";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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
    final challenges = widget.battleService.challenges;
    final itemCount = challenges.length + requests.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: itemCount == 0
          ? const Center(
              child: Text(
                'No notifications at the moment.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: itemCount,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index < challenges.length) {
                  final challenge = challenges[index];
                  final modeLabel = challenge.mode == 'word_chain'
                      ? 'Word Chain'
                      : 'Classic';
                  final languageLabel =
                      '${challenge.language[0].toUpperCase()}${challenge.language.substring(1)}';

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.sports_esports_outlined),
                    ),
                    title: Text('${challenge.fromName} challenged you'),
                    subtitle: Text('$modeLabel • $languageLabel'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            widget.battleService.respondToChallenge(
                              challenge.challengeId,
                              accept: false,
                            );
                          },
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            widget.battleService.respondToChallenge(
                              challenge.challengeId,
                              accept: true,
                            );
                          },
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  );
                }

                final requestIndex = index - challenges.length;
                final req = requests[requestIndex];
                final subtitle = StringBuffer()
                  ..write('Rating: ${req.fromRating}');
                if (req.createdAt != null) {
                  subtitle.write(
                    ' • ${req.createdAt!.toLocal().toString().split(".").first}',
                  );
                }

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
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
