import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/plugins/database_view/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/mobile_database_settings_button.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileTabBarHeader extends StatefulWidget {
  const MobileTabBarHeader({super.key});

  @override
  State<MobileTabBarHeader> createState() => _MobileTabBarHeaderState();
}

class _MobileTabBarHeaderState extends State<MobileTabBarHeader> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
      builder: (context, state) {
        final currentView = state.tabBars.firstWhereIndexedOrNull(
          (index, tabBar) => index == state.selectedIndex,
        );

        if (currentView == null) {
          return const SizedBox.shrink();
        }

        controller.text = currentView.view.name;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  _buildViewIconButton(currentView.view),
                  const HSpace(8.0),
                  Expanded(
                    child: FlowyTextField(
                      autoFocus: false,
                      maxLines: null,
                      controller: controller,
                      textAlignVertical: TextAlignVertical.top,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textStyle: Theme.of(context).textTheme.titleLarge,
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          context.read<ViewBloc>().add(
                                ViewEvent.rename(value),
                              );
                        }
                      },
                      onCanceled: () {
                        controller.text = currentView.view.name;
                      },
                    ),
                  ),
                  MobileDatabaseSettingsButton(
                    controller: state
                        .tabBarControllerByViewId[currentView.viewId]!
                        .controller,
                    toggleExtension: ToggleExtensionNotifier(),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
            ),
          ],
        );
      },
    );
  }

  Widget _buildViewIconButton(ViewPB view) {
    final icon = view.icon.value.isNotEmpty
        ? EmojiText(
            emoji: view.icon.value,
            fontSize: 24.0,
          )
        : SizedBox.square(
            dimension: 26.0,
            child: view.defaultIcon(),
          );
    return FlowyButton(
      text: icon,
      useIntrinsicWidth: true,
      onTap: () async {
        final result = await context.push<EmojiPickerResult>(
          MobileEmojiPickerScreen.routeName,
        );
        if (context.mounted && result != null) {
          await ViewBackendService.updateViewIcon(
            viewId: view.id,
            viewIcon: result.emoji,
          );
        }
      },
    );
  }
}
