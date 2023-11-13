import 'dart:io';

import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/workspace/application/doc/doc_listener.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

class MobileRecentView extends StatefulWidget {
  const MobileRecentView({
    super.key,
    required this.view,
    required this.height,
  });

  final ViewPB view;
  final double height;

  @override
  State<MobileRecentView> createState() => _MobileRecentViewState();
}

class _MobileRecentViewState extends State<MobileRecentView> {
  late final ViewListener viewListener;
  late ViewPB view;
  late final DocumentListener documentListener;

  @override
  void initState() {
    super.initState();

    view = widget.view;

    viewListener = ViewListener(
      viewId: view.id,
    )..start(
        onViewUpdated: (view) {
          setState(() {
            this.view = view;
          });
        },
      );

    documentListener = DocumentListener(id: view.id)
      ..start(
        didReceiveUpdate: (document) {
          setState(() {
            view = view;
          });
        },
      );
  }

  @override
  void dispose() {
    viewListener.stop();
    documentListener.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = view.icon.value;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.pushView(view),
      child: Container(
        height: widget.height,
        width: widget.height,
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: widget.height / 2.0,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: _buildCoverWidget(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: icon.isNotEmpty
                    ? FlowyText(
                        icon,
                        fontSize: 30.0,
                      )
                    : SizedBox.square(
                        dimension: 32.0,
                        child: view.defaultIcon(),
                      ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: widget.height / 2.0,
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 8.0,
                  top: 14.0,
                  right: 8.0,
                ),
                child: FlowyText(
                  view.name,
                  maxLines: 2,
                  fontSize: 16.0,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverWidget() {
    return FutureBuilder<Node?>(
      future: _getPageNode(),
      builder: ((context, snapshot) {
        final node = snapshot.data;
        final placeholder = Container(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        );
        if (node == null) {
          return placeholder;
        }
        final type = CoverType.fromString(
          node.attributes[DocumentHeaderBlockKeys.coverType],
        );
        final cover =
            node.attributes[DocumentHeaderBlockKeys.coverDetails] as String?;
        if (cover == null) {
          return placeholder;
        }
        switch (type) {
          case CoverType.file:
            if (isURL(cover)) {
              return CachedNetworkImage(
                imageUrl: cover,
                fit: BoxFit.cover,
              );
            }
            final imageFile = File(cover);
            if (!imageFile.existsSync()) {
              return placeholder;
            }
            return Image.file(
              imageFile,
            );
          case CoverType.asset:
            return Image.asset(
              cover,
              fit: BoxFit.cover,
            );
          case CoverType.color:
            final color = cover.tryToColor() ?? Colors.white;
            return Container(
              color: color,
            );
          case CoverType.none:
            return placeholder;
        }
      }),
    );
  }

  Future<Node?> _getPageNode() async {
    final data = await DocumentEventGetDocumentData(
      OpenDocumentPayloadPB(documentId: view.id),
    ).send();
    final document = data.fold((l) => l.toDocument(), (r) => null);
    if (document != null) {
      return document.root;
    }
    return null;
  }
}
