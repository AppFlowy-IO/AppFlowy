import 'dart:convert';
import 'dart:math';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_search_bar.dart';
import 'package:appflowy/util/debounce.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart' hide Icon;
import 'package:flutter/services.dart';

import 'icon_color_picker.dart';

// cache the icon groups to avoid loading them multiple times
List<IconGroup>? kIconGroups;

extension IconGroupFilter on List<IconGroup> {
  String? findSvgContent(String key) {
    final values = key.split('/');
    if (values.length != 2) {
      return null;
    }
    final groupName = values[0];
    final iconName = values[1];
    final svgString = kIconGroups
        ?.firstWhereOrNull(
          (group) => group.name == groupName,
        )
        ?.icons
        .firstWhereOrNull(
          (icon) => icon.name == iconName,
        )
        ?.content;
    return svgString;
  }

  (IconGroup, Icon) randomIcon() {
    final random = Random();
    final group = this[random.nextInt(length)];
    final icon = group.icons[random.nextInt(group.icons.length)];
    return (group, icon);
  }
}

Future<List<IconGroup>> loadIconGroups() async {
  if (kIconGroups != null) {
    return kIconGroups!;
  }

  final stopwatch = Stopwatch()..start();
  final jsonString = await rootBundle.loadString('assets/icons/icons.json');
  try {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final iconGroups = json.entries.map(IconGroup.fromMapEntry).toList();
    kIconGroups = iconGroups;
    return iconGroups;
  } catch (e) {
    Log.error('Failed to decode icons.json', e);
    return [];
  } finally {
    stopwatch.stop();
    Log.info('Loaded icon groups in ${stopwatch.elapsedMilliseconds}ms');
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: IconSearchBar(
            onRandomTap: () {
              final value = kIconGroups?.randomIcon();
              if (value == null) {
                return;
              }
              final color = generateRandomSpaceColor();
              widget.onSelectedIcon(value.$1, value.$2, color);
            },
            onKeywordChanged: (keyword) => {
              debounce.call(() {
                this.keyword.value = keyword;
              }),
            },
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
              children: iconGroup.icons.map(
                (icon) {
                  return _Icon(
                    icon: icon,
                    mutex: mutex,
                    onSelectedColor: (context, color) {
                      widget.onSelectedIcon(iconGroup, icon, color);
                      PopoverContainer.of(context).close();
                    },
                  );
                },
              ).toList(),
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
  final void Function(BuildContext context, String color) onSelectedColor;

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
      popupBuilder: (context) {
        return Container(
          padding: const EdgeInsets.all(6.0),
          child: IconColorPicker(
            onSelected: (color) => onSelectedColor(context, color),
          ),
        );
      },
    );
  }
}
