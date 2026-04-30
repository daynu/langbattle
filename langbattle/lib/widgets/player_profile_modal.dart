import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/widgets/language_flag.dart';
import 'package:langbattle/widgets/user_avatar.dart';

Future<void> showPlayerProfileModal({
  required BuildContext context,
  required BattleService battleService,
  required String userId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _PlayerProfileSheet(battleService: battleService, userId: userId),
  );
}

class _PlayerProfileSheet extends StatefulWidget {
  final BattleService battleService;
  final String userId;

  const _PlayerProfileSheet({
    required this.battleService,
    required this.userId,
  });

  @override
  State<_PlayerProfileSheet> createState() => _PlayerProfileSheetState();
}

class _PlayerProfileSheetState extends State<_PlayerProfileSheet> {
  late final Future<PlayerPublicProfile> _profileFuture;
  bool _showChallengeSetup = false;
  String _selectedMode = 'classic';
  String _selectedLanguage = 'english';

  static const List<Map<String, String>> _modes = [
    {'key': 'classic', 'label': 'Classic'},
    {'key': 'word_chain', 'label': 'Word Chain'},
  ];

  static const List<Map<String, String>> _languages = [
    {'key': 'english', 'label': 'English'},
    {'key': 'german', 'label': 'German'},
    {'key': 'french', 'label': 'French'},
  ];

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.battleService.requestPlayerProfile(widget.userId);
  }

  String _formatJoined(DateTime? createdAt) {
    if (createdAt == null) return 'Joined date unknown';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Joined ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  Future<void> _reportPlayer(PlayerPublicProfile profile) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report player'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'What happened?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = reason?.trim() ?? '';
    if (trimmed.isEmpty) return;

    widget.battleService.reportPlayer(profile.userId, trimmed);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Report submitted')));
  }

  void _sendChallenge(PlayerPublicProfile profile) {
    widget.battleService.challengePlayer(
      profile.userId,
      mode: _selectedMode,
      language: _selectedLanguage,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Challenge sent to ${profile.name}')),
    );
    Navigator.pop(context);
  }

  Widget _buildProfilePage(PlayerPublicProfile profile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            UserAvatar(
              name: profile.name,
              base64Image: profile.avatarBase64,
              size: 76,
              borderRadius: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Color(0xFF2D2F2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatJoined(profile.createdAt),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A5C58),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              LanguageFlag(
                language: profile.bestLanguage,
                width: 54,
                height: 38,
                borderRadius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile.bestLanguage[0].toUpperCase()}${profile.bestLanguage.substring(1)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D2F2C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${profile.bestRank} • ${profile.bestRating} ELO',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A5C58),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => setState(() => _showChallengeSetup = true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFDC003),
                  foregroundColor: const Color(0xFF553E00),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text(
                  'Challenge',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reportPlayer(profile),
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Report player'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFAB2D00),
                  side: const BorderSide(color: Color(0xFFAB2D00)),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChallengePage(PlayerPublicProfile profile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _showChallengeSetup = false),
              icon: const Icon(Icons.arrow_back_rounded),
              color: const Color(0xFF553E00),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Challenge ${profile.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Color(0xFF2D2F2C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Game type',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w900,
            color: Color(0xFF5A5C58),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _modes.map((mode) {
            final key = mode['key']!;
            final selected = _selectedMode == key;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: mode == _modes.last ? 0 : 8),
                child: _ChallengeOption(
                  selected: selected,
                  icon: key == 'word_chain' ? Icons.link : Icons.track_changes,
                  label: mode['label']!,
                  onTap: () => setState(() => _selectedMode = key),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const Text(
          'Language',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w900,
            color: Color(0xFF5A5C58),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _languages.map((language) {
            final key = language['key']!;
            final selected = _selectedLanguage == key;
            return ChoiceChip(
              selected: selected,
              showCheckmark: false,
              avatar: LanguageFlag(
                language: key,
                width: 24,
                height: 18,
                borderRadius: 5,
              ),
              label: Text(language['label']!),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected
                    ? const Color(0xFF553E00)
                    : const Color(0xFF5A5C58),
              ),
              selectedColor: const Color(0xFFFFF4C7),
              backgroundColor: const Color(0xFFF7F7F2),
              side: BorderSide(
                color: selected
                    ? const Color(0xFFFDC003)
                    : const Color(0xFFE1E1DC),
              ),
              onSelected: (_) => setState(() => _selectedLanguage = key),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: () => _sendChallenge(profile),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFDC003),
            foregroundColor: const Color(0xFF553E00),
            minimumSize: const Size.fromHeight(52),
          ),
          child: const Text(
            'Send challenge',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D2F2C).withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: FutureBuilder<PlayerPublicProfile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return SizedBox(
                  height: 180,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.error_outline, color: Color(0xFFAB2D00)),
                      SizedBox(height: 10),
                      Text('Could not load player profile'),
                    ],
                  ),
                );
              }

              final profile = snapshot.data!;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _showChallengeSetup
                    ? _buildChallengePage(profile)
                    : _buildProfilePage(profile),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChallengeOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChallengeOption({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          height: 76,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF4C7) : const Color(0xFFF7F7F2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFDC003)
                  : const Color(0xFFE1E1DC),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(0xFF553E00)
                    : const Color(0xFF5A5C58),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: selected
                        ? const Color(0xFF553E00)
                        : const Color(0xFF5A5C58),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
