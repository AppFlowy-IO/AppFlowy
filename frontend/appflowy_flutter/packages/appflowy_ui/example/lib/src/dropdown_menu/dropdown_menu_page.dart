import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class AFDropDownMenuItem with AFDropDownMenuMixin {
  const AFDropDownMenuItem({
    required this.label,
  });

  @override
  final String label;
}

class DropdownMenuPage extends StatefulWidget {
  const DropdownMenuPage({super.key});

  @override
  State<DropdownMenuPage> createState() => _DropdownMenuPageState();
}

class _DropdownMenuPageState extends State<DropdownMenuPage> {
  List<AFDropDownMenuItem> selectedItems = [];
  bool isDisabled = false;
  bool isMultiselect = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Stack(
      children: [
        Positioned(
          left: theme.spacing.xxl,
          top: theme.spacing.xxl,
          child: Container(
            padding: EdgeInsets.all(
              theme.spacing.m,
            ),
            decoration: BoxDecoration(
              color: theme.backgroundColorScheme.primary,
              borderRadius: BorderRadius.circular(theme.borderRadius.m),
              boxShadow: theme.shadow.medium,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOption(
                  'is disabled',
                  isDisabled,
                  (value) {
                    setState(() => isDisabled = value);
                  },
                ),
                // _buildOption(
                //   'multiselect',
                //   isMultiselect,
                //   (value) {
                //     setState(() => isMultiselect = value);
                //   },
                // ),
              ],
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: 240,
            child: AFDropDownMenu(
              items: items,
              selectedItems: selectedItems,
              isDisabled: isDisabled,
              // isMultiselect: isMultiselect,
              onSelected: (value) {
                if (value != null) {
                  setState(() {
                    if (isMultiselect) {
                      if (selectedItems.contains(value)) {
                        selectedItems.remove(value);
                      } else {
                        selectedItems.add(value);
                      }
                    } else {
                      selectedItems
                        ..clear()
                        ..add(value);
                    }
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(
    String label,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: Text(label),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  static const items = [
    AFDropDownMenuItem(label: 'Item 1'),
    AFDropDownMenuItem(label: 'Item 2'),
    AFDropDownMenuItem(label: 'Item 3'),
    AFDropDownMenuItem(label: 'Item 4'),
    AFDropDownMenuItem(label: 'Item 5'),
  ];
}
