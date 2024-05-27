import 'dart:io';

import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/application/recent/recent_view_bloc.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/flowy_gradient_colors.dart';
import 'package:appflowy/util/string_extension.dart';
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
                      Expanded(child: _buildCover(context, state)),
                      Expanded(child: _buildTitle(context, state)),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildIcon(context, state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCover(BuildContext context, RecentViewState state) {
    return Padding(
      padding: const EdgeInsets.only(top: 1.0, left: 1.0, right: 1.0),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        child: _RecentCover(
          coverTypeV1: state.coverTypeV1,
          coverTypeV2: state.coverTypeV2,
          value: state.coverValue,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, RecentViewState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 2),
      // hack: minLines currently not supported in Text widget.
      // https://github.com/flutter/flutter/issues/31134
      child: Stack(
        children: [
          FlowyText.medium(
            view.name,
            fontSize: 16.0,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const FlowyText(
            "\n\n",
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context, RecentViewState state) {
    return Padding(
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
    );
  }
}

class MobileRecentViewV2 extends StatelessWidget {
  const MobileRecentViewV2({
    super.key,
    required this.sectionView,
  });

  final SectionViewPB sectionView;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecentViewBloc>(
      create: (context) => RecentViewBloc(view: sectionView.item)
        ..add(
          const RecentViewEvent.initial(),
        ),
      child: BlocBuilder<RecentViewBloc, RecentViewState>(
        builder: (context, state) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.pushView(sectionView.item),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VSpace(22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTitle(context, state)),
                    _buildCover(context, state),
                  ],
                ),
                const VSpace(12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAuthor(context),
                    const Spacer(),
                    _buildLastViewed(context),
                  ],
                ),
                const VSpace(22),
                const Divider(height: 1),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCover(BuildContext context, RecentViewState state) {
    return SizedBox(
      width: 84,
      height: 60,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _RecentCover(
          coverTypeV1: state.coverTypeV1,
          coverTypeV2: state.coverTypeV2,
          value: state.coverValue,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, RecentViewState state) {
    var name = sectionView.item.name;
    final icon = sectionView.item.icon.value;
    if (icon.isNotEmpty) {
      name = '$icon $name';
    }
    return FlowyText.semibold(
      name,
      fontSize: 16.0,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAuthor(BuildContext context) {
    return FlowyText.regular(
      'Lucas Xu',
      fontSize: 14.0,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildLastViewed(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      sectionView.timestamp.toInt() * 1000,
    );
    return FlowyText.regular(
      date.toIso8601String(),
      fontSize: 13.0,
      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
    );
  }
}

class _RecentCover extends StatelessWidget {
  const _RecentCover({
    required this.coverTypeV1,
    this.coverTypeV2,
    this.value,
  });

  final CoverType coverTypeV1;
  final PageStyleCoverImageType? coverTypeV2;
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
    if (coverTypeV2 != null) {
      return _buildCoverV2(context, value, placeholder);
    }
    return _buildCoverV1(context, value, placeholder);
  }

  Widget _buildCoverV2(BuildContext context, String value, Widget placeholder) {
    final type = coverTypeV2;
    if (type == null) {
      return placeholder;
    }
    if (type == PageStyleCoverImageType.customImage ||
        type == PageStyleCoverImageType.unsplashImage) {
      final userProfilePB = Provider.of<UserProfilePB?>(context);
      return FlowyNetworkImage(
        url: value,
        userProfilePB: userProfilePB,
      );
    }

    if (type == PageStyleCoverImageType.builtInImage) {
      return Image.asset(
        PageStyleCoverImageType.builtInImagePath(value),
        fit: BoxFit.cover,
      );
    }

    if (type == PageStyleCoverImageType.pureColor) {
      final color = value.coverColor(context);
      if (color != null) {
        return ColoredBox(
          color: color,
        );
      }
    }

    if (type == PageStyleCoverImageType.gradientColor) {
      return Container(
        decoration: BoxDecoration(
          gradient: FlowyGradientColor.fromId(value).linear,
        ),
      );
    }

    if (type == PageStyleCoverImageType.localImage) {
      return Image.file(
        File(value),
        fit: BoxFit.cover,
      );
    }

    return placeholder;
  }

  Widget _buildCoverV1(BuildContext context, String value, Widget placeholder) {
    switch (coverTypeV1) {
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
