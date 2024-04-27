import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/recent_views_list.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_field.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_results_list.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CommandPalette extends InheritedWidget {
  CommandPalette({
    super.key,
    required Widget? child,
  }) : super(child: _CommandPaletteController(child: child));

  static CommandPalette of(BuildContext context) {
    final CommandPalette? result =
        context.dependOnInheritedWidgetOfExactType<CommandPalette>();

    assert(result != null, "CommandPalette could not be found");

    return result!;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class _ToggleCommandPaletteIntent extends Intent {
  const _ToggleCommandPaletteIntent();
}

class _CommandPaletteController extends StatefulWidget {
  const _CommandPaletteController({
    required this.child,
  });

  final Widget? child;

  @override
  State<_CommandPaletteController> createState() =>
      _CommandPaletteControllerState();
}

class _CommandPaletteControllerState extends State<_CommandPaletteController> {
  final ValueNotifier<bool> _toggleNotifier = ValueNotifier<bool>(false);
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _toggleNotifier.addListener(_onToggle);
  }

  @override
  void dispose() {
    _toggleNotifier.removeListener(_onToggle);
    super.dispose();
  }

  void _onToggle() {
    if (_toggleNotifier.value && !_isOpen) {
      _isOpen = true;
      FlowyOverlay.show(
        context: context,
        builder: (_) => BlocProvider.value(
          value: context.read<CommandPaletteBloc>(),
          child: CommandPaletteModal(shortcutBuilder: _buildShortcut),
        ),
      ).then((_) {
        _isOpen = false;
        _toggleNotifier.value = false;
      });
    } else if (!_toggleNotifier.value && _isOpen) {
      FlowyOverlay.pop(context);
      _isOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) =>
      _buildShortcut(widget.child ?? const SizedBox.shrink());

  Widget _buildShortcut(Widget child) => FocusableActionDetector(
        actions: {
          _ToggleCommandPaletteIntent:
              CallbackAction<_ToggleCommandPaletteIntent>(
            onInvoke: (intent) =>
                _toggleNotifier.value = !_toggleNotifier.value,
          ),
        },
        shortcuts: {
          LogicalKeySet(
            PlatformExtension.isMacOS
                ? LogicalKeyboardKey.meta
                : LogicalKeyboardKey.control,
            LogicalKeyboardKey.keyP,
          ): const _ToggleCommandPaletteIntent(),
        },
        child: child,
      );
}

class CommandPaletteModal extends StatelessWidget {
  const CommandPaletteModal({super.key, required this.shortcutBuilder});

  final Widget Function(Widget) shortcutBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommandPaletteBloc, CommandPaletteState>(
      builder: (context, state) => FlowyDialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 100),
        constraints: const BoxConstraints(maxHeight: 420, maxWidth: 510),
        expandHeight: false,
        child: shortcutBuilder(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchField(query: state.query, isLoading: state.isLoading),
              if ((state.query?.isEmpty ?? true) ||
                  state.isLoading && state.results.isEmpty) ...[
                const Divider(height: 0),
                Flexible(
                  child: RecentViewsList(
                    onSelected: () => FlowyOverlay.pop(context),
                  ),
                ),
              ],
              if (state.results.isNotEmpty) ...[
                const Divider(height: 0),
                Flexible(
                  child: SearchResultsList(
                    trash: state.trash,
                    results: state.results,
                  ),
                ),
              ],
              _CommandPaletteFooter(
                shouldShow: state.results.isNotEmpty &&
                    (state.query?.isNotEmpty ?? false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandPaletteFooter extends StatelessWidget {
  const _CommandPaletteFooter({required this.shouldShow});

  final bool shouldShow;

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AFThemeExtension.of(context).lightGreyHover,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const FlowyText.semibold('TAB', fontSize: 10),
          ),
          const HSpace(4),
          FlowyText(LocaleKeys.commandPalette_navigateHint.tr(), fontSize: 11),
        ],
      ),
    );
  }
}
