import 'package:flutter/material.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';

class TypeOptionButton extends StatelessWidget {
  const TypeOptionButton({
    super.key,
    this.onTap,
    this.onHover,
    required this.text,
  });

  final VoidCallback? onTap;
  final void Function(bool)? onHover;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(text),
        onTap: onTap,
        onHover: onHover,
        rightIcon: const FlowySvg(FlowySvgs.more_s),
      ),
    );
  }
}

class TypeOptionList<T> extends StatelessWidget {
  const TypeOptionList({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
    this.width = 120,
  });

  final Map<String, T> options;
  final T selectedOption;
  final Function(T option) onSelected;
  final double width;

  @override
  Widget build(BuildContext context) {
    final List<TypeOptionCell<T>> cells = [];
    options.forEach(
      (title, option) => cells.add(
        TypeOptionCell<T>(
          option: option,
          title: title,
          onSelected: onSelected,
          isSelected: selectedOption == option,
        ),
      ),
    );

    return SizedBox(
      width: width,
      child: ListView.separated(
        shrinkWrap: true,
        separatorBuilder: (context, index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        itemCount: cells.length,
        itemBuilder: (BuildContext context, int index) {
          return cells[index];
        },
      ),
    );
  }
}

class TypeOptionCell<T> extends StatelessWidget {
  const TypeOptionCell({
    super.key,
    required this.option,
    required this.title,
    required this.onSelected,
    required this.isSelected,
  });

  final T option;
  final String title;
  final Function(T option) onSelected;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    Widget? checkmark;
    if (isSelected) {
      checkmark = const FlowySvg(FlowySvgs.check_s);
    }

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(title),
        rightIcon: checkmark,
        onTap: () => onSelected(option),
      ),
    );
  }
}
