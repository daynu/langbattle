import 'dart:async';

import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/widgets/player_profile_modal.dart';

class FriendsPage extends StatefulWidget {
  final BattleService battleService;

  const FriendsPage({super.key, required this.battleService});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late TextEditingController _searchController;
  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _sub = widget.battleService.stream.listen((event) {
      final type = event["type"];
      if (!mounted) return;
      if (type == "friends_list" ||
          type == "friend_added" ||
          type == "search_players_result") {
        setState(() {});
      }
      if (type == "error") {
        final message = event["message"]?.toString() ?? "Something went wrong";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      if (type == "friend_removed") {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Friend removed")));
        widget.battleService.requestFriendsList();
      }
    });

    widget.battleService.requestFriendsList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.battleService.searchPlayersByName(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final friends = widget.battleService.friends;
    final searchResults = widget.battleService.searchResults;
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search players by name',
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isSearching
                  ? _buildSearchResults(searchResults, friends)
                  : _buildFriendsList(friends),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    List<PlayerSearchResult> results,
    List<FriendInfo> friends,
  ) {
    if (_searchController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No players found with that name yet.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final player = results[index];
        final isSelf = player.isSelf;
        final isAlreadyFriend =
            isSelf ||
            friends.any((f) => f.userId == player.userId) ||
            player.isFriend;

        return ListTile(
          onTap: isSelf
              ? null
              : () => showPlayerProfileModal(
                  context: context,
                  battleService: widget.battleService,
                  userId: player.userId,
                ),
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(player.name),
          subtitle: Text('Rating: ${player.rating}'),
          trailing: isSelf
              ? const Text('You', style: TextStyle(color: Colors.grey))
              : isAlreadyFriend
              ? const Icon(Icons.check, color: Colors.green)
              : TextButton(
                  onPressed: () =>
                      widget.battleService.addFriendById(player.userId),
                  child: const Text('Add'),
                ),
        );
      },
    );
  }

  Widget _buildFriendsList(List<FriendInfo> friends) {
    if (friends.isEmpty) {
      return const Center(
        child: Text(
          'No friends yet.\nSearch by name to find new players to add.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: friends.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final friend = friends[index];
        return ListTile(
          onTap: () => showPlayerProfileModal(
            context: context,
            battleService: widget.battleService,
            userId: friend.userId,
          ),
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(friend.name),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: () => widget.battleService.removeFriend(friend.userId),
          ),
          subtitle: Text('Rating: ${friend.rating}'),
        );
      },
    );
  }
}
