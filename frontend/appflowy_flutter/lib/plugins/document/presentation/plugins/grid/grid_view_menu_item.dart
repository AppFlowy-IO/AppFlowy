import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/plugins/base/insert_page_command.dart';
import 'package:appflowy/workspace/application/app/app_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

SelectionMenuItem gridViewMenuItem(DocumentBloc documentBloc) =>
    SelectionMenuItem(
      name: LocaleKeys.document_slashMenu_grid_createANewGrid.tr(),
      icon: (editorState, onSelected) {
        return svgWidget(
          'editor/grid',
          size: const Size.square(18.0),
          color: onSelected
              ? editorState.editorStyle.selectionMenuItemSelectedIconColor
              : editorState.editorStyle.selectionMenuItemIconColor,
        );
      },
      keywords: ['grid'],
      handler: (editorState, menuService, context) async {
        if (!documentBloc.view.hasAppId()) {
          return;
        }

        final appId = documentBloc.view.appId;
        final service = AppBackendService();

        final result = (await service.createView(
          appId: appId,
          name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
          layoutType: ViewLayoutTypePB.Grid,
        ))
            .getLeftOrNull();

        // If the result is null, then something went wrong here.
        if (result == null) {
          return;
        }

        final app =
            (await service.readApp(appId: result.appId)).getLeftOrNull();
        // We should show an error dialog.
        if (app == null) {
          return;
        }

        final view =
            (await service.getView(result.appId, result.id)).getLeftOrNull();
        // As this.
        if (view == null) {
          return;
        }

        editorState.insertPage(app, view);
      },
    );
