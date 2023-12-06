import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log, UploadImageMenu;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:string_validator/string_validator.dart';

class ImagePlaceholder extends StatefulWidget {
  const ImagePlaceholder({
    super.key,
    required this.node,
  });

  final Node node;

  @override
  State<ImagePlaceholder> createState() => ImagePlaceholderState();
}

class ImagePlaceholderState extends State<ImagePlaceholder> {
  final controller = PopoverController();
  late final editorState = context.read<EditorState>();

  @override
  Widget build(BuildContext context) {
    final Widget child = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FlowyHover(
        style: HoverStyle(
          borderRadius: BorderRadius.circular(4),
        ),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const HSpace(10),
              const FlowySvg(
                FlowySvgs.image_placeholder_s,
                size: Size.square(24),
              ),
              const HSpace(10),
              FlowyText(
                LocaleKeys.document_plugins_image_addAnImage.tr(),
              ),
            ],
          ),
        ),
      ),
    );

    if (PlatformExtension.isDesktopOrWeb) {
      return AppFlowyPopover(
        controller: controller,
        direction: PopoverDirection.bottomWithCenterAligned,
        constraints: const BoxConstraints(
          maxWidth: 540,
          maxHeight: 360,
          minHeight: 80,
        ),
        clickHandler: PopoverClickHandler.gestureDetector,
        popupBuilder: (context) {
          return UploadImageMenu(
            onSelectedLocalImage: (path) {
              controller.close();
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
                await insertLocalImage(path);
              });
            },
            onSelectedAIImage: (url) {
              controller.close();
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
                await insertAIImage(url);
              });
            },
            onSelectedNetworkImage: (url) {
              controller.close();
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
                await insertNetworkImage(url);
              });
            },
          );
        },
        child: child,
      );
    } else {
      return GestureDetector(
        onTap: () {
          showUploadImageMenu();
        },
        child: child,
      );
    }
  }

  void showUploadImageMenu() {
    if (PlatformExtension.isDesktopOrWeb) {
      controller.show();
    } else {
      showMobileBottomSheet(
        context,
        title: LocaleKeys.editor_image.tr(),
        showHeader: true,
        showCloseButton: true,
        showDragHandle: true,
        builder: (context) {
          return ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 340,
              minHeight: 80,
            ),
            child: UploadImageMenu(
              supportTypes: const [
                UploadImageType.local,
                UploadImageType.url,
                UploadImageType.unsplash,
              ],
              onSelectedLocalImage: (path) async {
                context.pop();
                await insertLocalImage(path);
              },
              onSelectedAIImage: (url) async {
                context.pop();
                await insertAIImage(url);
              },
              onSelectedNetworkImage: (url) async {
                context.pop();
                await insertNetworkImage(url);
              },
            ),
          );
        },
      );
    }
  }

  Future<void> insertLocalImage(String? url) async {
    if (url == null || url.isEmpty) {
      controller.close();
      return;
    }
    final path = await getIt<ApplicationDataStorage>().getPath();
    final imagePath = p.join(
      path,
      'images',
    );
    try {
      // create the directory if not exists
      final directory = Directory(imagePath);
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
      final copyToPath = p.join(
        imagePath,
        '${uuid()}${p.extension(url)}',
      );
      await File(url).copy(
        copyToPath,
      );

      final transaction = editorState.transaction;
      transaction.updateNode(widget.node, {
        ImageBlockKeys.url: copyToPath,
      });
      await editorState.apply(transaction);
    } catch (e) {
      Log.error('cannot copy image file', e);
    }
  }

  Future<void> insertAIImage(String url) async {
    if (url.isEmpty || !isURL(url)) {
      // show error
      showSnackBarMessage(
        context,
        LocaleKeys.document_imageBlock_error_invalidImage.tr(),
      );
      return;
    }

    final path = await getIt<ApplicationDataStorage>().getPath();
    final imagePath = p.join(
      path,
      'images',
    );
    try {
      // create the directory if not exists
      final directory = Directory(imagePath);
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
      final uri = Uri.parse(url);
      final copyToPath = p.join(
        imagePath,
        '${uuid()}${p.extension(uri.path)}',
      );

      final response = await get(uri);
      await File(copyToPath).writeAsBytes(response.bodyBytes);

      final transaction = editorState.transaction;
      transaction.updateNode(widget.node, {
        ImageBlockKeys.url: copyToPath,
      });
      await editorState.apply(transaction);
    } catch (e) {
      Log.error('cannot save image file', e);
    }
  }

  Future<void> insertNetworkImage(String url) async {
    if (url.isEmpty || !isURL(url)) {
      // show error
      showSnackBarMessage(
        context,
        LocaleKeys.document_imageBlock_error_invalidImage.tr(),
      );
      return;
    }

    final transaction = editorState.transaction;
    transaction.updateNode(widget.node, {
      ImageBlockKeys.url: url,
    });
    await editorState.apply(transaction);
  }
}
