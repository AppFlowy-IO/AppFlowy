import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcut_cubit.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCustomizeShortcuts extends StatelessWidget {
  const SettingsCustomizeShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShortcutsCubit>(
      create: (context) => ShortcutsCubit()..fetchShortcuts(),
      child: const CustomizeShortcutsView(),
    );
  }
}

class CustomizeShortcutsView extends StatelessWidget {
  const CustomizeShortcutsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShortcutsCubit, ShortcutsState>(
      builder: (context, state) {
        switch (state.status) {
          case ShortcutsStatus.success:
            return ShortcutsListView(shortcuts: state.shortcuts);
          case ShortcutsStatus.failure:
            return const ShortcutsErrorView();
          case ShortcutsStatus.initial:
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            );
        }
      },
    );
  }
}

class ShortcutsListView extends StatelessWidget {
  final List<ShortcutEvent> shortcuts;
  const ShortcutsListView({super.key, required this.shortcuts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FlowyText.medium(
          "Customize Shortcuts",
          overflow: TextOverflow.ellipsis,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: shortcuts.length,
            itemBuilder: ((context, i) {
              return ShortcutsListTile(shortcutEvent: shortcuts[i]);
            }),
          ),
        )
      ],
    );
  }
}

class ShortcutsListTile extends StatelessWidget {
  final ShortcutEvent shortcutEvent;
  const ShortcutsListTile({
    super.key,
    required this.shortcutEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText.regular(
            shortcutEvent.key,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        FlowyTextButton(
          shortcutEvent.command,
          onPressed: () {
            print(shortcutEvent);
          },
        )
      ],
    );
  }
}

class ShortcutsErrorView extends StatelessWidget {
  const ShortcutsErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: FlowyText.medium(
        "Could Not Load Customized Shortcuts",
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
