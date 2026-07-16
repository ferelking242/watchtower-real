import 'package:flutter/material.dart';
import 'package:watchtower_real/core/theme/tokens.dart';

class SearchFiltersSheet extends StatefulWidget {
  const SearchFiltersSheet({super.key});

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  int _sort = 0;
  int _category = 0;
  int _date = 0;

  static const _sorts = ['Pertinence', "Nb j'aime", 'Date'];
  static const _categories = ['Tous', 'Non vus', 'Vus', "Aimés", 'Suivis'];
  static const _dates = ['Tous', '24h', 'Semaine', 'Mois', '3 mois', '6 mois'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTokens.space24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppTokens.space12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppTokens.colorBgLightCard,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Annuler',
                      style: AppTokens.bodyM.copyWith(color: Colors.black)),
                ),
                Text('Filtres',
                    style: AppTokens.titleM.copyWith(color: Colors.black)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Appliquer',
                      style: AppTokens.bodyM.copyWith(
                          color: _sort != 0 || _category != 0 || _date != 0
                              ? AppTokens.colorBrand
                              : AppTokens.colorTextSecondaryDark,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          _FilterSection('Trier par', _sorts, _sort, (i) => setState(() => _sort = i)),
          _FilterSection('Catégorie', _categories, _category, (i) => setState(() => _category = i)),
          _FilterSection('Date', _dates, _date, (i) => setState(() => _date = i)),
        ],
      ),
    );
  }

  Widget _FilterSection(
      String label, List<String> options, int selected, Function(int) onSel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.space16, 0, AppTokens.space16, AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTokens.titleM.copyWith(
                  color: Colors.black, fontSize: 14)),
          const SizedBox(height: AppTokens.space8),
          Wrap(
            spacing: AppTokens.space8,
            runSpacing: AppTokens.space8,
            children: options.asMap().entries.map((e) {
              final active = e.key == selected;
              return GestureDetector(
                onTap: () => onSel(e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space16, vertical: AppTokens.space8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: active
                            ? Colors.black
                            : AppTokens.colorDividerLight,
                        width: active ? 1.5 : 1),
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusPill),
                    color: active ? Colors.black : Colors.white,
                  ),
                  child: Text(e.value,
                      style: AppTokens.bodyS.copyWith(
                          color: active ? Colors.white : Colors.black)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
