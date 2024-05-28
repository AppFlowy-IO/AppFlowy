import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/application/recent/recent_view_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/flowy_gradient_colors.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:string_validator/string_validator.dart';

class MobileViewCard extends StatelessWidget {
  const MobileViewCard({
    super.key,
    required this.view,
    this.timestamp,
  });

  final ViewPB view;
  final Int64? timestamp;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecentViewBloc>(
      create: (context) => RecentViewBloc(view: view)
        ..add(
          const RecentViewEvent.initial(),
        ),
      child: BlocBuilder<RecentViewBloc, RecentViewState>(
        builder: (context, state) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.pushView(view),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: _buildDescription(context, state)),
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
    return Row(
      children: [
        Flexible(child: _buildAuthor(context)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.0),
          child: FlowySvg(FlowySvgs.dot_s),
        ),
        _buildLastViewed(context),
      ],
    );
  }

  Widget _buildCover(BuildContext context, RecentViewState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: _ViewCover(
        coverTypeV1: state.coverTypeV1,
        coverTypeV2: state.coverTypeV2,
        value: state.coverValue,
      ),
    );
  }

  Widget _buildTitle(BuildContext context, RecentViewState state) {
    var name = view.name;
    final icon = view.icon.value;
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
      view.createdBy.toString(),
      fontSize: 13.0,
      color: Theme.of(context).hintColor,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLastViewed(BuildContext context) {
    if (timestamp == null) {
      return const SizedBox.shrink();
    }
    final date = _formatTimestamp(
      timestamp!.toInt() * 1000,
    );
    return FlowyText.regular(
      date,
      fontSize: 13.0,
      color: Theme.of(context).hintColor,
    );
  }

  String _formatTimestamp(int timestamp) {
    final now = DateTime.now();
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(dateTime);
    final String date;

    if (difference.inMinutes < 1) {
      date = LocaleKeys.sideBar_justNow.tr();
    } else if (difference.inHours < 1) {
      // Less than 1 hour
      date = LocaleKeys.sideBar_minutesAgo
          .tr(namedArgs: {'count': difference.inMinutes.toString()});
    } else if (difference.inHours >= 1 && difference.inHours < 24) {
      // Between 1 hour and 24 hours
      date = DateFormat('h:mm a').format(dateTime);
    } else if (difference.inDays >= 1 && dateTime.year == now.year) {
      // More than 24 hours but within the current year
      date = DateFormat('M/d, h:mm a').format(dateTime);
    } else {
      // Other cases (previous years)
      date = DateFormat('M/d/yyyy, h:mm a').format(dateTime);
    }

    if (difference.inHours >= 1) {
      return '${LocaleKeys.sideBar_lastViewed.tr()} $date';
    }

    return date;
  }
}

class _ViewCover extends StatelessWidget {
  const _ViewCover({
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
      color: const Color(0xFFE1FBFF),
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
