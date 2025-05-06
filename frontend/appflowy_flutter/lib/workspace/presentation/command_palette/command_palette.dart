import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/recent_views_list.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_field.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_results_list.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

import 'widgets/search_ask_ai_entrance.dart';

class CommandPalette extends InheritedWidget {
  CommandPalette({
    super.key,
    required Widget? child,
    required this.notifier,
  }) : super(
          child: _CommandPaletteController(notifier: notifier, child: child),
        );

  final ValueNotifier<CommandPaletteNotifierValue> notifier;

  static CommandPalette of(BuildContext context) {
    final CommandPalette? result =
        context.dependOnInheritedWidgetOfExactType<CommandPalette>();

    assert(result != null, "CommandPalette could not be found");

    return result!;
  }

  void toggle({
    UserWorkspaceBloc? workspaceBloc,
  }) {
    final value = notifier.value;
    notifier.value = notifier.value.copyWith(
      isOpen: !value.isOpen,
      userWorkspaceBloc: workspaceBloc,
    );
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
    required this.notifier,
  });

  final Widget? child;
  final ValueNotifier<CommandPaletteNotifierValue> notifier;

  @override
  State<_CommandPaletteController> createState() =>
      _CommandPaletteControllerState();
}

class _CommandPaletteControllerState extends State<_CommandPaletteController> {
  late ValueNotifier<CommandPaletteNotifierValue> _toggleNotifier =
      widget.notifier;
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

  @override
  void didUpdateWidget(_CommandPaletteController oldWidget) {
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_onToggle);
      _toggleNotifier = widget.notifier;
      _toggleNotifier.addListener(_onToggle);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _onToggle() {
    if (_toggleNotifier.value.isOpen && !_isOpen) {
      _isOpen = true;
      final workspaceBloc = _toggleNotifier.value.userWorkspaceBloc;
      FlowyOverlay.show(
        context: context,
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<CommandPaletteBloc>()),
            if (workspaceBloc != null) BlocProvider.value(value: workspaceBloc),
          ],
          child: CommandPaletteModal(shortcutBuilder: _buildShortcut),
        ),
      ).then((_) {
        _isOpen = false;
        _toggleNotifier.value = _toggleNotifier.value.copyWith(isOpen: false);
      });
    } else if (!_toggleNotifier.value.isOpen && _isOpen) {
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
            onInvoke: (intent) => _toggleNotifier.value = _toggleNotifier.value
                .copyWith(isOpen: !_toggleNotifier.value.isOpen),
          ),
        },
        shortcuts: {
          LogicalKeySet(
            UniversalPlatform.isMacOS
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
    final workspaceState = context.read<UserWorkspaceBloc?>()?.state;
    final showAskingAI =
        workspaceState?.userProfile.workspaceType == WorkspaceTypePB.ServerW;
    final theme = AppFlowyTheme.of(context);

    return BlocBuilder<CommandPaletteBloc, CommandPaletteState>(
      builder: (context, state) => FlowyDialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 100),
        constraints: const BoxConstraints(
          maxHeight: 600,
          maxWidth: 800,
          minHeight: 600,
        ),
        expandHeight: false,
        child: shortcutBuilder(
          // Change mainAxisSize to max so Expanded works correctly.
          Column(
            children: [
              SearchField(query: state.query, isLoading: state.searching),
              if (showAskingAI) ...[
                Divider(height: 1, color: theme.borderColorScheme.primary),
                SearchAskAiEntrance(),
              ],
              if (state.query?.isEmpty ?? true) ...[
                if (!showAskingAI)
                  Divider(height: 1, color: theme.borderColorScheme.primary),
                Flexible(
                  child: RecentViewsList(
                    onSelected: () => FlowyOverlay.pop(context),
                  ),
                ),
              ],
              if (state.combinedResponseItems.isNotEmpty &&
                  (state.query?.isNotEmpty ?? false)) ...[
                if (!showAskingAI) const Divider(height: 0),
                Flexible(
                  child: SearchResultList(
                    trash: state.trash,
                    resultItems: state.combinedResponseItems.values.toList(),
                    resultSummaries: state.resultSummaries,
                  ),
                ),
              ]
              // When there are no results and the query is not empty and not loading,
              // show the no results message, centered in the available space.
              else if ((state.query?.isNotEmpty ?? false) &&
                  !state.searching) ...[
                Divider(height: 1, color: theme.borderColorScheme.primary),
                Expanded(
                  child: const _NoResultsHint(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Updated _NoResultsHint now centers its content.
class _NoResultsHint extends StatelessWidget {
  const _NoResultsHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FlowyText.regular(
        LocaleKeys.commandPalette_noResultsHint.tr(),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class CommandPaletteNotifierValue {
  CommandPaletteNotifierValue({
    this.isOpen = false,
    this.userWorkspaceBloc,
  });

  final bool isOpen;
  final UserWorkspaceBloc? userWorkspaceBloc;

  CommandPaletteNotifierValue copyWith({
    bool? isOpen,
    UserWorkspaceBloc? userWorkspaceBloc,
  }) {
    return CommandPaletteNotifierValue(
      isOpen: isOpen ?? this.isOpen,
      userWorkspaceBloc: userWorkspaceBloc ?? this.userWorkspaceBloc,
    );
  }
}
