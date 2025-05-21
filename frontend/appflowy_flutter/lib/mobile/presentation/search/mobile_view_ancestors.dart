import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_special_styles.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'view_ancestor_cache.dart';
part 'mobile_view_ancestors.freezed.dart';

class ViewAncestorBloc extends Bloc<ViewAncestorEvent, ViewAncestorState> {
  ViewAncestorBloc(String viewId) : super(ViewAncestorState.initial(viewId)) {
    _cache = getIt<ViewAncestorCache>();
    _dispatch();
  }

  late final ViewAncestorCache _cache;

  void _dispatch() {
    on<ViewAncestorEvent>(
      (event, emit) async {
        await event.map(
          initial: (e) async {
            emit(state.copyWith(isLoading: true));

            final ancester = await _cache.getAncestor(
              state.viewId,
              onRefresh: (ancestor) {
                if (!emit.isDone) {
                  emit(state.copyWith(ancestor: ancestor, isLoading: false));
                }
              },
            );
            emit(state.copyWith(ancestor: ancester, isLoading: false));
          },
        );
      },
    );
    add(const ViewAncestorEvent.initial());
  }
}

@freezed
class ViewAncestorEvent with _$ViewAncestorEvent {
  const factory ViewAncestorEvent.initial() = Initial;
}

@freezed
class ViewAncestorState with _$ViewAncestorState {
  const factory ViewAncestorState({
    required ViewAncestor ancestor,
    required String viewId,
    @Default(true) bool isLoading,
  }) = _ViewAncestorState;

  factory ViewAncestorState.initial(String viewId) => ViewAncestorState(
        viewId: viewId,
        ancestor: ViewAncestor.empty(),
      );
}

extension ViewAncestorTextExtension on ViewAncestorState {
  Widget buildPath(BuildContext context, {TextStyle? style}) {
    final theme = AppFlowyTheme.of(context);
    final ancestors = ancestor.ancestors;
    final textStyle = style ??
        theme.textStyle.caption.standard(color: theme.textColorScheme.tertiary);
    final textHeight = (textStyle.fontSize ?? 0.0) * (textStyle.height ?? 1.0);
    if (isLoading) return VSpace(textHeight);
    return LayoutBuilder(
      builder: (context, constrains) {
        final List<String> displayPath = ancestors.map((e) => e.name).toList();
        if (displayPath.isEmpty) return const SizedBox.shrink();
        TextPainter textPainter =
            _buildTextPainter(displayPath.join(' / '), textStyle);
        textPainter.layout(maxWidth: constrains.maxWidth);
        if (textPainter.didExceedMaxLines && displayPath.length > 2) {
          displayPath.removeAt(displayPath.length - 2);
          displayPath.insert(displayPath.length - 1, '...');
        }
        textPainter = _buildTextPainter(displayPath.join(' / '), textStyle);
        textPainter.layout(maxWidth: constrains.maxWidth);
        while (textPainter.didExceedMaxLines && displayPath.length > 3) {
          displayPath.removeAt(displayPath.length - 2);
          textPainter = _buildTextPainter(displayPath.join(' / '), textStyle);
          textPainter.layout(maxWidth: constrains.maxWidth);
        }
        return Text(
          displayPath.join(' / '),
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  TextPainter _buildTextPainter(String text, TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      );

  Widget buildOnelinePath(BuildContext context) {
    final ancestors = ancestor.ancestors;
    List<String> displayPath = ancestors.map((e) => e.name).toList();
    if (ancestors.length > 2) {
      displayPath = [ancestors.first.name, '...', ancestors.last.name];
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          WidgetSpan(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('-', style: context.searchPanelPath),
            ),
          ),
          TextSpan(
            text: displayPath.join(' / '),
            style: context.searchPanelPath,
          ),
        ],
      ),
    );
  }
}
