import 'dart:convert';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_search_bar.dart';
import 'package:appflowy/util/debounce.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart' hide Icon;
import 'package:flutter/services.dart';

// cache the icon groups to avoid loading them multiple times
List<IconGroup>? _iconGroups;

Future<List<IconGroup>> _loadIconGroups() async {
  if (_iconGroups != null) {
    return _iconGroups!;
  }

  final jsonString = await rootBundle.loadString('assets/icons/icons.json');
  try {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final iconGroups = json.entries.map(IconGroup.fromMapEntry).toList();
    _iconGroups = iconGroups;
    return iconGroups;
  } catch (e) {
    Log.error('Failed to decode icons.json', e);
    return [];
  }
}

class FlowyIconPicker extends StatefulWidget {
  const FlowyIconPicker({
    super.key,
  });

  @override
  State<FlowyIconPicker> createState() => _FlowyIconPickerState();
}

class _FlowyIconPickerState extends State<FlowyIconPicker> {
  late final Future<List<IconGroup>> iconGroups;
  final ValueNotifier<String> keyword = ValueNotifier('');
  final debounce = Debounce(duration: const Duration(milliseconds: 150));

  @override
  void initState() {
    super.initState();

    iconGroups = _loadIconGroups();
  }

  @override
  void dispose() {
    keyword.dispose();
    debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconSearchBar(
          onRandomTap: () {},
          onKeywordChanged: (keyword) => {
            debounce.call(() {
              this.keyword.value = keyword;
            }),
          },
        ),
        Expanded(
          child: FutureBuilder(
            future: iconGroups,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: SizedBox.square(
                    dimension: 24.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                    ),
                  ),
                );
              }
              final iconGroups = snapshot.data as List<IconGroup>;
              return ValueListenableBuilder(
                valueListenable: keyword,
                builder: (_, keyword, __) {
                  if (keyword.isNotEmpty) {
                    final filteredIconGroups = iconGroups
                        .map((iconGroup) => iconGroup.filter(keyword))
                        .where((iconGroup) => iconGroup.icons.isNotEmpty)
                        .toList();
                    return IconPicker(
                      iconGroups: filteredIconGroups,
                    );
                  }
                  return IconPicker(
                    iconGroups: iconGroups,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class IconPicker extends StatelessWidget {
  const IconPicker({
    super.key,
    required this.iconGroups,
  });

  final List<IconGroup> iconGroups;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: iconGroups.length,
      itemBuilder: (context, index) {
        final iconGroup = iconGroups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlowyText(
              iconGroup.displayName,
              fontSize: 12,
              figmaLineHeight: 18.0,
              color: const Color(0x80171717),
            ),
            const VSpace(4.0),
            Wrap(
              children: iconGroup.icons
                  .map(
                    (icon) => _Icon(
                      icon: icon,
                      onTap: () {},
                    ),
                  )
                  .toList(),
            ),
            const VSpace(12.0),
          ],
        );
      },
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({
    required this.icon,
    required this.onTap,
  });

  final Icon icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: icon.displayName,
      child: FlowyButton(
        onTap: onTap,
        useIntrinsicWidth: true,
        margin: const EdgeInsets.all(8.0),
        text: Center(
          child: FlowySvg.string(
            icon.content,
            size: const Size.square(20),
            color: const Color(0xFF171717),
            opacity: 0.7,
          ),
        ),
      ),
    );
  }
}
