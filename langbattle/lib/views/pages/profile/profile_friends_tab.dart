import 'dart:async';
import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/widgets/user_avatar.dart';

class ProfileFriendsTab extends StatefulWidget {
  final BattleService battleService;

  const ProfileFriendsTab({super.key, required this.battleService});

  @override
  State<ProfileFriendsTab> createState() => _ProfileFriendsTabState();
}

class _ProfileFriendsTabState extends State<ProfileFriendsTab> {
  late TextEditingController _searchController;
  Timer? _debounce;
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _sub = widget.battleService.stream.listen((event) {
      if (!mounted) return;
      final type = event['type'];
      if (type == 'friends_list' ||
          type == 'friend_added' ||
          type == 'friend_removed' ||
          type == 'search_players_result') {
        setState(() {});
      }
      if (type == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                event['message']?.toString() ?? 'Something went wrong'),
          ),
        );
      }
    });
    widget.battleService.requestFriendsList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.battleService.searchPlayersByName(value.trim());
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final friends = widget.battleService.friends;
    final searchResults = widget.battleService.searchResults;
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search players by name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isSearching
                ? _buildSearchResults(searchResults, friends)
                : _buildFriendsList(friends),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
      List<PlayerSearchResult> results, List<FriendInfo> friends) {
    if (results.isEmpty) {
      return const Center(
          child: Text('No players found.', textAlign: TextAlign.center));
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final player = results[index];
        final isAlreadyFriend = player.isSelf ||
            friends.any((f) => f.userId == player.userId) ||
            player.isFriend;
        return ListTile(
          leading: UserAvatar(
  name: player.name, // or friend.name
  base64Image: null, // FriendInfo doesn't carry avatarBase64 yet
  size: 40,
  borderRadius: 8,
),
          title: Text(player.name),
          subtitle: Text('Rating: ${player.rating}'),
          trailing: player.isSelf
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
          'No friends yet.\nSearch by name to add players.',
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
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(friend.name),
          subtitle: Text('Rating: ${friend.rating}'),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: () =>
                widget.battleService.removeFriend(friend.userId),
          ),
        );
      },
    );
  }
}