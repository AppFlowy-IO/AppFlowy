import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/application/recent/recent_view_bloc.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/flowy_gradient_colors.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/application/settings/date_time/time_format_ext.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:string_validator/string_validator.dart';
import 'package:time/time.dart';

enum MobileViewCardType {
  recent,
  favorite;

  String get lastOperationHintText => switch (this) {
        MobileViewCardType.recent => LocaleKeys.sideBar_lastViewed.tr(),
        MobileViewCardType.favorite => LocaleKeys.sideBar_favoriteAt.tr(),
      };
}

class MobileViewCard extends StatelessWidget {
  const MobileViewCard({
    super.key,
    required this.view,
    this.timestamp,
    required this.type,
  });

  final ViewPB view;
  final Int64? timestamp;
  final MobileViewCardType type;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ViewBloc>(
          create: (context) => ViewBloc(view: view, shouldLoadChildViews: false)
            ..add(const ViewEvent.initial()),
        ),
        BlocProvider(
          create: (context) =>
              RecentViewBloc(view: view)..add(const RecentViewEvent.initial()),
        ),
      ],
      child: BlocBuilder<RecentViewBloc, RecentViewState>(
        builder: (context, state) {
          return Slidable(
            endActionPane: buildEndActionPane(
              context,
              [
                MobilePaneActionType.more,
                context.watch<ViewBloc>().state.view.isFavorite
                    ? MobilePaneActionType.removeFromFavorites
                    : MobilePaneActionType.addToFavorites,
              ],
              cardType: type,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (_) => context.pushView(view),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(child: _buildDescription(context, state)),
                  const HSpace(20.0),
                  SizedBox(
                    width: 84,
                    height: 60,
                    child: _buildCover(context, state),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDescription(BuildContext context, RecentViewState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // page icon & page title
        _buildTitle(context, state),
        const VSpace(12.0),
        // author & last viewed
        _buildNameAndLastViewed(context, state),
      ],
    );
  }

  Widget _buildNameAndLastViewed(BuildContext context, RecentViewState state) {
    final supportAvatar = isURL(state.icon);
    if (!supportAvatar) {
      return _buildLastViewed(context);
    }
    return Row(
      children: [
        _buildAvatar(context, state),
        Flexible(child: _buildAuthor(context, state)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.0),
          child: FlowySvg(FlowySvgs.dot_s),
        ),
        _buildLastViewed(context),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, RecentViewState state) {
    final userProfile = Provider.of<UserProfilePB?>(context);
    final iconUrl = userProfile?.iconUrl;
    if (iconUrl == null ||
        iconUrl.isEmpty ||
        view.createdBy != userProfile?.id) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2, right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: SizedBox.square(
          dimension: 16.0,
          child: FlowyNetworkImage(
            url: iconUrl,
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, RecentViewState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: _ViewCover(
        layout: view.layout,
        coverTypeV1: state.coverTypeV1,
        coverTypeV2: state.coverTypeV2,
        value: state.coverValue,
      ),
    );
  }

  Widget _buildTitle(BuildContext context, RecentViewState state) {
    final name = state.name;
    final icon = state.icon;
    final fontFamily = Platform.isAndroid || Platform.isLinux
        ? GoogleFonts.notoColorEmoji().fontFamily
        : null;
    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: icon,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w600,
                  fontFamily: fontFamily,
                ),
          ),
          if (icon.isNotEmpty) const WidgetSpan(child: HSpace(2.0)),
          TextSpan(
            text: name,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthor(BuildContext context, RecentViewState state) {
    return FlowyText.regular(
      // view.createdBy.toString(),
      'Lucas',
      fontSize: 12.0,
      color: Theme.of(context).hintColor,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLastViewed(BuildContext context) {
    final textColor = Theme.of(context).isLightMode
        ? const Color(0xFF171717)
        : Colors.white.withOpacity(0.45);
    if (timestamp == null) {
      return const SizedBox.shrink();
    }
    final date = _formatTimestamp(
      context,
      timestamp!.toInt() * 1000,
    );
    return FlowyText.regular(
      date,
      fontSize: 13.0,
      color: textColor,
    );
  }

  String _formatTimestamp(BuildContext context, int timestamp) {
    final now = DateTime.now();
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(dateTime);
    final String date;

    final dateFormate =
        context.read<AppearanceSettingsCubit>().state.dateFormat;
    final timeFormate =
        context.read<AppearanceSettingsCubit>().state.timeFormat;

    if (difference.inMinutes < 1) {
      date = LocaleKeys.sideBar_justNow.tr();
    } else if (difference.inHours < 1 && dateTime.isToday) {
      // Less than 1 hour
      date = LocaleKeys.sideBar_minutesAgo
          .tr(namedArgs: {'count': difference.inMinutes.toString()});
    } else if (difference.inHours >= 1 && dateTime.isToday) {
      // in same day
      date = timeFormate.formatTime(dateTime);
    } else {
      date = dateFormate.formatDate(dateTime, false);
    }

    if (difference.inHours >= 1) {
      return '${type.lastOperationHintText} $date';
    }

    return date;
  }
}

class _ViewCover extends StatelessWidget {
  const _ViewCover({
    required this.layout,
    required this.coverTypeV1,
    this.coverTypeV2,
    this.value,
  });

  final ViewLayoutPB layout;
  final CoverType coverTypeV1;
  final PageStyleCoverImageType? coverTypeV2;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final placeholder = _buildPlaceholder(context);
    final value = this.value;
    if (value == null) {
      return placeholder;
    }
    if (coverTypeV2 != null) {
      return _buildCoverV2(context, value, placeholder);
    }
    return _buildCoverV1(context, value, placeholder);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isLightMode = Theme.of(context).isLightMode;
    final (svg, color) = switch (layout) {
      ViewLayoutPB.Document => (
          FlowySvgs.m_document_thumbnail_m,
          isLightMode ? const Color(0xCCEDFBFF) : const Color(0x33658B90)
        ),
      ViewLayoutPB.Grid => (
          FlowySvgs.m_grid_thumbnail_m,
          isLightMode ? const Color(0xFFF5F4FF) : const Color(0x338B80AD)
        ),
      ViewLayoutPB.Board => (
          FlowySvgs.m_board_thumbnail_m,
          isLightMode ? const Color(0x7FE0FDD9) : const Color(0x3372936B),
        ),
      ViewLayoutPB.Calendar => (
          FlowySvgs.m_calendar_thumbnail_m,
          isLightMode ? const Color(0xFFFFF7F0) : const Color(0x33A68B77)
        ),
      ViewLayoutPB.Chat => (
          FlowySvgs.m_chat_thumbnail_m,
          isLightMode ? const Color(0x66FFE6FD) : const Color(0x33987195)
        ),
      _ => (
          FlowySvgs.m_document_thumbnail_m,
          isLightMode ? Colors.black : Colors.white
        )
    };
    return ColoredBox(
      color: color,
      child: Center(
        child: FlowySvg(
          svg,
          blendMode: null,
        ),
      ),
    );
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
