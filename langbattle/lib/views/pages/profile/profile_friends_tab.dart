import 'dart:async';
import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/widgets/player_profile_modal.dart';
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
      if (type == 'online_count') {
        widget.battleService.requestFriendsList();
      }
      if (type == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              event['message']?.toString() ?? 'Something went wrong',
            ),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search players by name',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF5A5C58)),
              filled: true,
              fillColor: const Color(0xFFF1F1EC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFFDC003)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
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
    );
  }

  Widget _buildSearchResults(
    List<PlayerSearchResult> results,
    List<FriendInfo> friends,
  ) {
    if (results.isEmpty) {
      return const Center(
        child: Text('No players found.', textAlign: TextAlign.center),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final player = results[index];
        final isAlreadyFriend =
            player.isSelf ||
            friends.any((f) => f.userId == player.userId) ||
            player.isFriend;
        return _FriendRow(
          onTap: player.isSelf
              ? null
              : () => showPlayerProfileModal(
                  context: context,
                  battleService: widget.battleService,
                  userId: player.userId,
                ),
          avatar: UserAvatar(
            name: player.name,
            base64Image: null,
            size: 40,
            borderRadius: 12,
          ),
          name: player.name,
          subtitle: 'Rating: ${player.rating}',
          trailing: player.isSelf
              ? const Text(
                  'You',
                  style: TextStyle(
                    color: Color(0xFF5A5C58),
                    fontWeight: FontWeight.w700,
                  ),
                )
              : isAlreadyFriend
              ? const Icon(Icons.check, color: Color(0xFF0D6661))
              : TextButton(
                  onPressed: () =>
                      widget.battleService.addFriendById(player.userId),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF553E00),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
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
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final friend = friends[index];
        return _FriendRow(
          onTap: () => showPlayerProfileModal(
            context: context,
            battleService: widget.battleService,
            userId: friend.userId,
          ),
          avatar: _FriendAvatar(friend: friend),
          name: friend.name,
          subtitle: 'Rating: ${friend.rating}',
          trailing: IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Color(0xFFAB2D00),
            ),
            onPressed: () => widget.battleService.removeFriend(friend.userId),
          ),
        );
      },
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  final FriendInfo friend;

  const _FriendAvatar({required this.friend});

  @override
  Widget build(BuildContext context) {
    final avatar = UserAvatar(
      name: friend.name,
      base64Image: friend.avatarBase64,
      size: 40,
      borderRadius: 12,
    );

    if (!friend.isOnline) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF0D6661),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendRow extends StatelessWidget {
  final Widget avatar;
  final String name;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _FriendRow({
    required this.avatar,
    required this.name,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE1E1DC)),
          ),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF2D2F2C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF5A5C58),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
