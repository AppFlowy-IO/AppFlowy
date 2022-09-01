import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GridGroupList extends StatelessWidget {
  const GridGroupList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _GridGroupCell extends StatelessWidget {
  const _GridGroupCell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    // final checkmark = field.visibility
    //     ? svgWidget('home/show', color: theme.iconColor)
    //     : svgWidget('home/hide', color: theme.iconColor);

    return Container();
  }
}
