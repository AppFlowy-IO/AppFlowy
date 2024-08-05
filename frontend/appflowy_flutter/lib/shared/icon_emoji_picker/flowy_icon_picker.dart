import 'dart:convert';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();

    iconGroups = _loadIconGroups();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: iconGroups,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final iconGroups = snapshot.data as List<IconGroup>;

        return ListView.builder(
          itemCount: iconGroups.length,
          itemBuilder: (context, index) {
            final iconGroup = iconGroups[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(iconGroup.name),
                Wrap(
                  children: iconGroup.icons
                      .map(
                        (icon) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FlowySvg.string(icon.content),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
