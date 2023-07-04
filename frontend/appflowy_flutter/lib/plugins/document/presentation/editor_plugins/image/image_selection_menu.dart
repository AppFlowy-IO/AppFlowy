import 'dart:io';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

final customImageMenuItem = SelectionMenuItem(
  name: AppFlowyEditorLocalizations.current.image,
  icon: (editorState, isSelected, style) => SelectionMenuIconWidget(
    name: 'image',
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['image', 'picture', 'img', 'photo'],
  handler: (editorState, menuService, context) {
    final container = Overlay.of(context);
    showImageMenu(
      container,
      editorState,
      menuService,
      onInsertImage: (url) async {
        // if the url is http, we can insert it directly
        // otherwise, if it's a file url, we need to copy the file to the app's document directory

        final regex = RegExp('^(http|https)://');
        if (regex.hasMatch(url)) {
          await editorState.insertImageNode(url);
        } else {
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
            await editorState.insertImageNode(copyToPath);
          } catch (e) {
            Log.error('cannot copy image file', e);
          }
        }
      },
    );
  },
);
