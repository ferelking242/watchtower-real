import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchtower_real/core/theme/tokens.dart';
import 'package:watchtower_real/features/search/search_results_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  bool _searching = false;
  String _query = '';

  static const _trending = [
    '#fyp', '#viral', '#redgift', '#dance', '#food',
    '#travel', '#nature', '#music', '#comedy', '#art',
  ];

  static const _history = [
    'redgift popular', 'trending now', 'live streams',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.colorBgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(
                  AppTokens.space16, AppTokens.space8,
                  AppTokens.space16, AppTokens.space8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTokens.colorBgLightSurface,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusPill),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (v) => setState(() {
                          _query = v;
                          _searching = v.isNotEmpty;
                        }),
                        onSubmitted: (v) {
                          if (v.isNotEmpty)
                            setState(() { _query = v; _searching = true; });
                        },
                        style: AppTokens.bodyM.copyWith(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Rechercher sur Redgift',
                          hintStyle: AppTokens.bodyM.copyWith(
                              color: AppTokens.colorTextSecondaryDark),
                          prefixIcon: const Icon(Icons.search,
                              color: AppTokens.colorTextSecondaryDark),
                          suffixIcon: _query.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _ctrl.clear();
                                    setState(() { _query = ''; _searching = false; });
                                  },
                                  child: const Icon(Icons.close,
                                      color: AppTokens.colorTextSecondaryDark),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text('Annuler',
                        style: AppTokens.bodyM.copyWith(color: Colors.black)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _searching
                  ? SearchResultsScreen(query: _query)
                  : _Suggestions(
                      history: _history,
                      trending: _trending,
                      onTap: (s) {
                        _ctrl.text = s;
                        setState(() { _query = s; _searching = true; });
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.history,
    required this.trending,
    required this.onTap,
  });
  final List<String> history, trending;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (history.isNotEmpty) ...[
          _SectionHeader('Recherches récentes'),
          ...history.map((h) => ListTile(
                leading: const Icon(Icons.history,
                    color: AppTokens.colorTextSecondaryDark),
                title: Text(h,
                    style: AppTokens.bodyM.copyWith(color: Colors.black)),
                trailing: const Icon(Icons.north_west,
                    size: 16, color: AppTokens.colorTextSecondaryDark),
                onTap: () => onTap(h),
              )),
          const Divider(height: 1, color: AppTokens.colorDividerLight),
        ],
        _SectionHeader('Tendances Redgift'),
        Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Wrap(
            spacing: AppTokens.space8,
            runSpacing: AppTokens.space8,
            children: trending
                .map((t) => GestureDetector(
                      onTap: () => onTap(t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTokens.colorBgLightSurface,
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusPill),
                        ),
                        child: Text(t,
                            style:
                                AppTokens.bodyS.copyWith(color: Colors.black)),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.space16, AppTokens.space16,
          AppTokens.space16, AppTokens.space8),
      child: Text(title,
          style: AppTokens.titleM.copyWith(color: Colors.black)),
    );
  }
}
