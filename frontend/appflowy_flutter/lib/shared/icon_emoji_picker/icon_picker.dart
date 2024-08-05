import 'dart:convert';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_search_bar.dart';
import 'package:appflowy/util/debounce.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart' hide Icon;
import 'package:flutter/services.dart';

import 'icon_color_picker.dart';

// cache the icon groups to avoid loading them multiple times
List<IconGroup>? kIconGroups;

Future<List<IconGroup>> loadIconGroups() async {
  if (kIconGroups != null) {
    return kIconGroups!;
  }

  final jsonString = await rootBundle.loadString('assets/icons/icons.json');
  try {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final iconGroups = json.entries.map(IconGroup.fromMapEntry).toList();
    kIconGroups = iconGroups;
    return iconGroups;
  } catch (e) {
    Log.error('Failed to decode icons.json', e);
    return [];
  }
}

class FlowyIconPicker extends StatefulWidget {
  const FlowyIconPicker({
    super.key,
    required this.onSelectedIcon,
  });

  final void Function(IconGroup group, Icon icon, String color) onSelectedIcon;

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

    iconGroups = loadIconGroups();
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
          child: kIconGroups != null
              ? _buildIcons(kIconGroups!)
              : FutureBuilder(
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
                    return _buildIcons(iconGroups);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIcons(List<IconGroup> iconGroups) {
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
            onSelectedIcon: widget.onSelectedIcon,
          );
        }
        return IconPicker(
          iconGroups: iconGroups,
          onSelectedIcon: widget.onSelectedIcon,
        );
      },
    );
  }
}

class IconPicker extends StatefulWidget {
  const IconPicker({
    super.key,
    required this.onSelectedIcon,
    required this.iconGroups,
  });

  final List<IconGroup> iconGroups;
  final void Function(IconGroup group, Icon icon, String color) onSelectedIcon;

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  final mutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.iconGroups.length,
      itemBuilder: (context, index) {
        final iconGroup = widget.iconGroups[index];
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
                      mutex: mutex,
                      onSelectedColor: (color) {
                        widget.onSelectedIcon(iconGroup, icon, color);
                      },
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
    required this.mutex,
    required this.onSelectedColor,
  });

  final Icon icon;
  final PopoverMutex mutex;
  final void Function(String color) onSelectedColor;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithCenterAligned,
      offset: const Offset(0, 6),
      mutex: mutex,
      child: FlowyTooltip(
        message: icon.displayName,
        preferBelow: false,
        child: FlowyButton(
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
      ),
      popupBuilder: (_) {
        return Container(
          padding: const EdgeInsets.all(6.0),
          child: IconColorPicker(
            onSelected: onSelectedColor,
          ),
        );
      },
    );
  }
}
