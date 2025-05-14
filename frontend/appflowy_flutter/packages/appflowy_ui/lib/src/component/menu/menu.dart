export 'menu_item.dart';
export 'section.dart';

import 'package:flutter/material.dart';

/// The main menu container widget, supporting sections, menu items, and optional search.
class AFMenu extends StatelessWidget {
  const AFMenu({
    super.key,
    required this.children,
    this.showSearch = false,
    this.onSearchChanged,
    this.searchText,
  });

  /// The list of widgets to display in the menu (sections or menu items).
  final List<Widget> children;

  /// Whether to show a search bar at the top of the menu.
  final bool showSearch;

  /// Callback when the search text changes.
  final ValueChanged<String>? onSearchChanged;

  /// The current search text.
  final String? searchText;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).cardColor,
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSearch)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  onChanged: onSearchChanged,
                  controller: searchText != null
                      ? TextEditingController(text: searchText)
                      : null,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).inputDecorationTheme.fillColor ??
                            Theme.of(context).hoverColor,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  ),
                ),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}
