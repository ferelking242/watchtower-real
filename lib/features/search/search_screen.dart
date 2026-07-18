import 'package:flutter/material.dart';
import 'package:watchtower_real/core/theme/tokens.dart';
import 'package:watchtower_real/features/search/search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  bool _searching = false;
  String _query = '';

  static const _history = [
    'best song',
    'france vs spain',
    'Best animated serie',
  ];

  static const _suggestions = [
    _Suggestion('BTS Munich Concert 2026', true, true),
    _Suggestion('Match France vs Espagne', true, true),
    _Suggestion('the best animation series', false, false),
    _Suggestion('best songs', false, false),
    _Suggestion('Trend Melon Glace', false, true),
    _Suggestion('Lamine Yamal demi-finale', false, true),
    _Suggestion('Samsung Galaxy Z Fold 8', false, true),
    _Suggestion('DRAGON AGE ABSOLUTION', false, false),
    _Suggestion('Dance sensation', false, false),
    _Suggestion('animes recommendations', false, false),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    if (v.isNotEmpty) setState(() { _query = v; _searching = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar ──────────────────────────────────────────
            _SearchBar(
              ctrl: _ctrl,
              query: _query,
              onChanged: (v) => setState(() {
                _query = v;
                _searching = v.isNotEmpty;
              }),
              onSubmit: _onSearch,
              onClear: () => setState(() { _query = ''; _searching = false; }),
              onVoice: () => _openVoiceSearch(context),
              onCancel: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: _searching
                  ? SearchResultsScreen(query: _query)
                  : _SuggestionsView(
                      history: _history,
                      suggestions: _suggestions,
                      onTap: (s) {
                        _ctrl.text = s;
                        _onSearch(s);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVoiceSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VoiceSearchModal(),
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.ctrl,
    required this.query,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
    required this.onVoice,
    required this.onCancel,
  });
  final TextEditingController ctrl;
  final String query;
  final void Function(String) onChanged, onSubmit;
  final VoidCallback onClear, onVoice, onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          // Back arrow
          GestureDetector(
            onTap: onCancel,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.black, size: 20),
            ),
          ),

          // Search field
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: TextField(
                controller: ctrl,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: onSubmit,
                style: const TextStyle(
                    color: Colors.black, fontSize: 14, height: 1.4),
                decoration: InputDecoration(
                  hintText: 'Rechercher',
                  hintStyle: const TextStyle(
                      color: Color(0xFF8A8A8A), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF8A8A8A), size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (query.isNotEmpty)
                        GestureDetector(
                          onTap: onClear,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.cancel_rounded,
                                color: Color(0xFF8A8A8A), size: 18),
                          ),
                        ),
                      GestureDetector(
                        onTap: onVoice,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(Icons.mic_rounded,
                              color: Color(0xFF8A8A8A), size: 20),
                        ),
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Search action
          GestureDetector(
            onTap: () => onSubmit(ctrl.text),
            child: const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                'Rechercher',
                style: TextStyle(
                  color: Color(0xFFFE2C55),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Suggestions view ─────────────────────────────────────────────────────────
class _SuggestionsView extends StatefulWidget {
  const _SuggestionsView({
    required this.history,
    required this.suggestions,
    required this.onTap,
  });
  final List<String> history;
  final List<_Suggestion> suggestions;
  final void Function(String) onTap;

  @override
  State<_SuggestionsView> createState() => _SuggestionsViewState();
}

class _SuggestionsViewState extends State<_SuggestionsView> {
  late final List<String> _history;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _history = List.from(widget.history);
  }

  void _dismiss(String item) => setState(() => _history.remove(item));

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // History
        ..._history.map((h) => _HistoryTile(
              text: h,
              onTap: () => widget.onTap(h),
              onDismiss: () => _dismiss(h),
            )),
        if (_history.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() => _showAll = !_showAll),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Afficher plus',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  Icon(
                    _showAll
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

        // "Tu pourrais aimer"
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Tu pourrais aimer',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...widget.suggestions.map((s) => _SuggestionTile(
              suggestion: s,
              onTap: () => widget.onTap(s.text),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── History tile ─────────────────────────────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.text,
    required this.onTap,
    required this.onDismiss,
  });
  final String text;
  final VoidCallback onTap, onDismiss;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                color: Color(0xFF8A8A8A), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFF8A8A8A), size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Suggestion tile ──────────────────────────────────────────────────────────
class _Suggestion {
  const _Suggestion(this.text, this.isHot, this.isTrending);
  final String text;
  final bool isHot, isTrending;
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.onTap});
  final _Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dotColor = suggestion.isHot
        ? const Color(0xFFFE2C55)
        : suggestion.isTrending
            ? const Color(0xFFFF8C00)
            : const Color(0xFFCCCCCC);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            // Colored dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                suggestion.text,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),
            if (suggestion.isTrending)
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFFFE2C55),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Voice search modal ───────────────────────────────────────────────────────
class _VoiceSearchModal extends StatefulWidget {
  const _VoiceSearchModal();

  @override
  State<_VoiceSearchModal> createState() => _VoiceSearchModalState();
}

class _VoiceSearchModalState extends State<_VoiceSearchModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.black, size: 24),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Row(
                      children: [
                        Icon(Icons.language_rounded,
                            color: Colors.black, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Français',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // "Parle maintenant..."
            const Text(
              'Parle maintenant...',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const Spacer(),

            // Animated pulse circle
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFE2C55).withOpacity(0.15),
                  ),
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFE2C55),
                      ),
                      child: const Center(
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Sound search
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.only(bottom: 40),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.music_note_rounded,
                        color: Colors.black, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Recherche de son',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
