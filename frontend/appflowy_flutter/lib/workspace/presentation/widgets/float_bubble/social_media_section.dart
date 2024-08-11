import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';

class SocialMediaSection extends CustomActionCell {
  @override
  Widget buildWithContext(BuildContext context, PopoverController controller) {
    final List<Widget> children = [
      Divider(
        height: 1,
        color: Theme.of(context).dividerColor,
        thickness: 1.0,
      ),
    ];

    children.addAll(
      SocialMedia.values.map(
        (social) {
          return ActionCellWidget(
            action: SocialMediaWrapper(social),
            itemHeight: ActionListSizes.itemHeight,
            onSelected: (action) {
              switch (action.inner) {
                case SocialMedia.reddit:
                  afLaunchUrlString(
                    'https://www.reddit.com/r/AppFlowy/',
                  );
                case SocialMedia.twitter:
                  afLaunchUrlString(
                    'https://x.com/appflowy',
                  );
                case SocialMedia.forum:
                  afLaunchUrlString('https://forum.appflowy.io/');
              }
            },
          );
        },
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: children,
      ),
    );
  }
}

enum SocialMedia { forum, twitter, reddit }

class SocialMediaWrapper extends ActionCell {
  SocialMediaWrapper(this.inner);

  final SocialMedia inner;
  @override
  Widget? leftIcon(Color iconColor) => inner.icons;

  @override
  String get name => inner.name;

  @override
  Color? textColor(BuildContext context) => inner.textColor(context);
}

extension QuestionBubbleExtension on SocialMedia {
  Color? textColor(BuildContext context) {
    switch (this) {
      case SocialMedia.reddit:
        return Theme.of(context).hintColor;

      case SocialMedia.twitter:
        return Theme.of(context).hintColor;

      case SocialMedia.forum:
        return Theme.of(context).hintColor;

      default:
        return null;
    }
  }

  String get name {
    switch (this) {
      case SocialMedia.forum:
        return "Community Forum";
      case SocialMedia.twitter:
        return "Twitter - @appflowy";
      case SocialMedia.reddit:
        return "Reddit - r/appflowy";
    }
  }

  Widget? get icons {
    switch (this) {
      case SocialMedia.reddit:
        return null;
      case SocialMedia.twitter:
        return null;
      case SocialMedia.forum:
        return null;
    }
  }
}
