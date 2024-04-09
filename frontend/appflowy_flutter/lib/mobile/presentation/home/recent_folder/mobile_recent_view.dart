import 'dart:io';

import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/application/recent/recent_view_bloc.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:string_validator/string_validator.dart';

class MobileRecentView extends StatelessWidget {
  const MobileRecentView({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider<RecentViewBloc>(
      create: (context) => RecentViewBloc(view: view)
        ..add(
          const RecentViewEvent.initial(),
        ),
      child: BlocBuilder<RecentViewBloc, RecentViewState>(
        builder: (context, state) {
          return GestureDetector(
            onTap: () => context.pushView(view),
            child: Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          child: _RecentCover(
                            coverType: state.coverType,
                            value: state.coverValue,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 18, 8, 2),
                          // hack: minLines currently not supported in Text widget.
                          // https://github.com/flutter/flutter/issues/31134
                          child: Stack(
                            children: [
                              FlowyText.medium(
                                view.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const FlowyText(
                                "\n\n",
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: state.icon.isNotEmpty
                        ? EmojiText(
                            emoji: state.icon,
                            fontSize: 30.0,
                          )
                        : SizedBox.square(
                            dimension: 32.0,
                            child: view.defaultIcon(),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecentCover extends StatelessWidget {
  const _RecentCover({
    required this.coverType,
    this.value,
  });

  final CoverType coverType;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      // random color, update it once we have a better placeholder
      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
    );
    final value = this.value;
    if (value == null) {
      return placeholder;
    }
    switch (coverType) {
      case CoverType.file:
        if (isURL(value)) {
          final userProfilePB = Provider.of<UserProfilePB?>(context);
          return FlowyNetworkImage(
            url: value,
            userProfilePB: userProfilePB,
          );
        }
        final imageFile = File(value);
        if (!imageFile.existsSync()) {
          return placeholder;
        }
        return Image.file(
          imageFile,
        );
      case CoverType.asset:
        return Image.asset(
          value,
          fit: BoxFit.cover,
        );
      case CoverType.color:
        final color = value.tryToColor() ?? Colors.white;
        return Container(
          color: color,
        );
      case CoverType.none:
        return placeholder;
    }
  }
}
