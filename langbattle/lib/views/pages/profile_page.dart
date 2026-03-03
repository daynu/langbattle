import 'dart:async';

import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/friends_page.dart';
import 'package:langbattle/views/pages/welcome_page.dart';

class ProfilePage extends StatefulWidget {
  final BattleService battleService;

  const ProfilePage({
    super.key,
    required this.battleService,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  StreamSubscription<Map<String, dynamic>>? _friendsSub;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.battleService.currentUser?.name ?? '',
    );

    _friendsSub = widget.battleService.stream.listen((event) {
      final type = event["type"];
      if (!mounted) return;
      if (type == "friends_list" || type == "friend_added") {
        setState(() {});
      }
    });

    widget.battleService.requestFriendsList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _friendsSub?.cancel();
    super.dispose();
  }

  void _saveDisplayName() {
    final user = widget.battleService.currentUser;
    final newName = _nameController.text.trim();
    if (user == null || newName.isEmpty || newName == user.name) {
      return;
    }

    // Update the in-memory session so the new name is reflected in the UI.
    widget.battleService.currentUser = user.copyWith(name: newName);

    // Optionally, an event could be sent to the backend here if supported.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.battleService.currentUser;
    final friendsCount = user?.friendsCount ?? widget.battleService.friends.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: user == null
          ? const Center(
              child: Text('Log in to see your profile'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        child: Icon(Icons.person, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Display name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: _saveDisplayName,
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overall ranking',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rating: ${user.rating}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Language rankings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...user.ratings.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key[0].toUpperCase() +
                                        entry.key.substring(1),
                                  ),
                                  Text(
                                    entry.value.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FriendsPage(
                              battleService: widget.battleService,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Friends',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              friendsCount == 1
                                  ? 'You have 1 friend connected.'
                                  : 'You have $friendsCount friends connected.',
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap to view your friends and add new ones.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      widget.battleService.logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WelcomePage(),
                          ),
                        );
                    }, 
                    child: const Text('Log out'),
                  ),
                ],
              ),
            ),
    );
  }
}