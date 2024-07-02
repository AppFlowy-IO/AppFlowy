import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/sidebar_space_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpacePermissionSwitch extends StatefulWidget {
  const SpacePermissionSwitch({
    super.key,
    required this.onPermissionChanged,
    this.spacePermission,
    this.showArrow = false,
  });

  final SpacePermission? spacePermission;
  final void Function(SpacePermission permission) onPermissionChanged;
  final bool showArrow;

  @override
  State<SpacePermissionSwitch> createState() => _SpacePermissionSwitchState();
}

class _SpacePermissionSwitchState extends State<SpacePermissionSwitch> {
  late SpacePermission spacePermission =
      widget.spacePermission ?? SpacePermission.publicToAll;
  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.regular(
          LocaleKeys.space_permission.tr(),
          fontSize: 14.0,
          color: Theme.of(context).hintColor,
        ),
        const VSpace(6.0),
        AppFlowyPopover(
          controller: popoverController,
          direction: PopoverDirection.bottomWithCenterAligned,
          constraints: const BoxConstraints(maxWidth: 500),
          offset: const Offset(0, 4),
          margin: EdgeInsets.zero,
          decoration: FlowyDecoration.decoration(
            Theme.of(context).cardColor,
            Theme.of(context).colorScheme.shadow,
            borderRadius: 10,
          ),
          popupBuilder: (_) => _buildPermissionButtons(),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: SpacePermissionButton(
              showArrow: true,
              permission: spacePermission,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionButtons() {
    return SizedBox(
      width: 452,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpacePermissionButton(
            permission: SpacePermission.publicToAll,
            onTap: () => _onPermissionChanged(SpacePermission.publicToAll),
          ),
          SpacePermissionButton(
            permission: SpacePermission.private,
            onTap: () => _onPermissionChanged(SpacePermission.private),
          ),
        ],
      ),
    );
  }

  void _onPermissionChanged(SpacePermission permission) {
    widget.onPermissionChanged(permission);

    setState(() {
      spacePermission = permission;
    });

    popoverController.close();
  }
}

class SpacePermissionButton extends StatelessWidget {
  const SpacePermissionButton({
    super.key,
    required this.permission,
    this.onTap,
    this.showArrow = false,
  });

  final SpacePermission permission;
  final VoidCallback? onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final (title, desc, icon) = switch (permission) {
      SpacePermission.publicToAll => (
          LocaleKeys.space_publicPermission.tr(),
          LocaleKeys.space_publicPermissionDescription.tr(),
          FlowySvgs.space_permission_public_s
        ),
      SpacePermission.private => (
          LocaleKeys.space_privatePermission.tr(),
          LocaleKeys.space_privatePermissionDescription.tr(),
          FlowySvgs.space_permission_private_s
        ),
    };

    return FlowyButton(
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      radius: BorderRadius.circular(10),
      iconPadding: 16.0,
      leftIcon: FlowySvg(icon),
      rightIcon: showArrow
          ? const FlowySvg(FlowySvgs.space_permission_dropdown_s)
          : null,
      text: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowyText.regular(title),
          const VSpace(4.0),
          FlowyText.regular(
            desc,
            fontSize: 12.0,
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class SpaceCancelOrConfirmButton extends StatelessWidget {
  const SpaceCancelOrConfirmButton({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmButtonName,
    this.confirmButtonColor,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmButtonName;
  final Color? confirmButtonColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0x1E14171B)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: FlowyButton(
            useIntrinsicWidth: true,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 9.0),
            text: FlowyText.regular(LocaleKeys.button_cancel.tr()),
            onTap: onCancel,
          ),
        ),
        const HSpace(12.0),
        DecoratedBox(
          decoration: ShapeDecoration(
            color: confirmButtonColor ?? Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: FlowyButton(
            useIntrinsicWidth: true,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 9.0),
            radius: BorderRadius.circular(8),
            text: FlowyText.regular(
              confirmButtonName,
              color: Colors.white,
            ),
            onTap: onConfirm,
          ),
        ),
      ],
    );
  }
}

class ConfirmDeletionPopup extends StatelessWidget {
  const ConfirmDeletionPopup({
    super.key,
    required this.title,
    required this.description,
    required this.onConfirm,
  });

  final String title;
  final String description;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 20.0,
        horizontal: 20.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FlowyText(
                title,
                fontSize: 14.0,
              ),
              const Spacer(),
              FlowyButton(
                useIntrinsicWidth: true,
                text: const FlowySvg(FlowySvgs.upgrade_close_s),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const VSpace(8.0),
          FlowyText.regular(
            description,
            fontSize: 12.0,
            color: Theme.of(context).hintColor,
            maxLines: 3,
            lineHeight: 1.4,
          ),
          const VSpace(20.0),
          SpaceCancelOrConfirmButton(
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () {
              onConfirm();
              Navigator.of(context).pop();
            },
            confirmButtonName: LocaleKeys.space_delete.tr(),
            confirmButtonColor: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class SpacePopup extends StatelessWidget {
  const SpacePopup({
    super.key,
    this.height,
    this.useIntrinsicWidth = true,
    this.expand = false,
    required this.showCreateButton,
    required this.child,
  });

  final bool showCreateButton;
  final bool useIntrinsicWidth;
  final bool expand;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? HomeSizes.workspaceSectionHeight,
      child: AppFlowyPopover(
        constraints: const BoxConstraints(maxWidth: 260),
        direction: PopoverDirection.bottomWithLeftAligned,
        clickHandler: PopoverClickHandler.gestureDetector,
        offset: const Offset(0, 4),
        popupBuilder: (_) => BlocProvider.value(
          value: context.read<SpaceBloc>(),
          child: SidebarSpaceMenu(
            showCreateButton: showCreateButton,
          ),
        ),
        child: FlowyButton(
          useIntrinsicWidth: useIntrinsicWidth,
          expand: expand,
          margin: const EdgeInsets.only(left: 3.0, right: 4.0),
          iconPadding: 10.0,
          text: child,
        ),
      ),
    );
  }
}

class CurrentSpace extends StatelessWidget {
  const CurrentSpace({
    super.key,
    this.onTapBlankArea,
    required this.space,
  });

  final ViewPB space;
  final VoidCallback? onTapBlankArea;

  @override
  Widget build(BuildContext context) {
    final child = FlowyTooltip(
      message: LocaleKeys.space_switchSpace.tr(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpaceIcon(
            dimension: 20,
            space: space,
            cornerRadius: 6.0,
          ),
          const HSpace(10),
          Flexible(
            child: FlowyText.medium(
              space.name,
              fontSize: 14.0,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const HSpace(4.0),
          FlowySvg(
            context.read<SpaceBloc>().state.isExpanded
                ? FlowySvgs.workspace_drop_down_menu_show_s
                : FlowySvgs.workspace_drop_down_menu_hide_s,
          ),
        ],
      ),
    );

    if (onTapBlankArea != null) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: FlowyHover(
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: child,
              ),
            ),
          ),
          Expanded(
            child: FlowyTooltip(
              message: LocaleKeys.space_movePageToSpace.tr(),
              child: GestureDetector(
                onTap: onTapBlankArea,
              ),
            ),
          ),
        ],
      );
    }

    return child;
  }
}

class SpacePages extends StatelessWidget {
  const SpacePages({
    super.key,
    required this.space,
    required this.isHovered,
    required this.isExpandedNotifier,
    required this.onSelected,
    this.rightIconsBuilder,
    this.disableSelectedStatus = false,
    this.onTertiarySelected,
    this.shouldIgnoreView,
  });

  final ViewPB space;
  final ValueNotifier<bool> isHovered;
  final PropertyValueNotifier<bool> isExpandedNotifier;
  final bool disableSelectedStatus;
  final ViewItemRightIconsBuilder? rightIconsBuilder;
  final ViewItemOnSelected onSelected;
  final ViewItemOnSelected? onTertiarySelected;
  final bool Function(ViewPB view)? shouldIgnoreView;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ViewBloc(view: space)..add(const ViewEvent.initial()),
      child: BlocBuilder<ViewBloc, ViewState>(
        builder: (context, state) {
          // filter the child views that should be ignored
          var childViews = state.view.childViews;
          if (shouldIgnoreView != null) {
            childViews = childViews
                .where((childView) => !shouldIgnoreView!(childView))
                .toList();
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: childViews
                .map(
                  (view) => ViewItem(
                    key: ValueKey('${space.id} ${view.id}'),
                    spaceType:
                        space.spacePermission == SpacePermission.publicToAll
                            ? FolderSpaceType.public
                            : FolderSpaceType.private,
                    isFirstChild: view.id == childViews.first.id,
                    view: view,
                    level: 0,
                    leftPadding: HomeSpaceViewSizes.leftPadding,
                    isFeedback: false,
                    isHovered: isHovered,
                    disableSelectedStatus: disableSelectedStatus,
                    isExpandedNotifier: isExpandedNotifier,
                    rightIconsBuilder: rightIconsBuilder,
                    onSelected: onSelected,
                    onTertiarySelected: onTertiarySelected,
                    shouldIgnoreView: shouldIgnoreView,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class SpaceSearchField extends StatefulWidget {
  const SpaceSearchField({
    super.key,
    required this.width,
    required this.onSearch,
  });

  final double width;
  final void Function(BuildContext context, String text) onSearch;

  @override
  State<SpaceSearchField> createState() => _SpaceSearchFieldState();
}

class _SpaceSearchFieldState extends State<SpaceSearchField> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: widget.width,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1.20,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: Color(0xFF00BCF0),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: CupertinoSearchTextField(
        onChanged: (text) => widget.onSearch(context, text),
        padding: EdgeInsets.zero,
        focusNode: focusNode,
        placeholder: LocaleKeys.search_label.tr(),
        prefixIcon: const FlowySvg(FlowySvgs.magnifier_s),
        prefixInsets: const EdgeInsets.only(left: 12.0, right: 8.0),
        suffixIcon: const Icon(Icons.close),
        suffixInsets: const EdgeInsets.only(right: 8.0),
        itemSize: 16.0,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        placeholderStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w400,
            ),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
            ),
      ),
    );
  }
}
