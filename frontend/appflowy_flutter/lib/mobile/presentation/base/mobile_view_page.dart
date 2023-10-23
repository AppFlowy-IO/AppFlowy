import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/error/error_page.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileViewPage extends StatefulWidget {
  const MobileViewPage({
    super.key,
    required this.id,
    this.title,
    required this.viewLayout,
  });

  /// view id
  final String id;
  final String? title;
  final ViewLayoutPB viewLayout;

  @override
  State<MobileViewPage> createState() => _MobileViewPageState();
}

class _MobileViewPageState extends State<MobileViewPage> {
  late final Future<Either<ViewPB, FlowyError>> future;

  @override
  void initState() {
    super.initState();

    future = ViewBackendService.getView(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, state) {
        Widget body;
        String? title;
        if (state.connectionState != ConnectionState.done) {
          body = const Center(
            child: CircularProgressIndicator(),
          );
        } else if (!state.hasData) {
          body = MobileErrorPage(
            message: LocaleKeys.error_loadingViewError.tr(),
          );
        } else {
          body = state.data!.fold((view) {
            title = view.name;
            return view.plugin().widgetBuilder.buildWidget(shrinkWrap: false);
          }, (error) {
            return MobileErrorPage(
              message: error.toString(),
            );
          });
        }
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: FlowyText(
              title ?? widget.title ?? '',
              fontSize: 14.0,
            ),
            leading: BackButton(
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: body,
          ),
        );
      },
    );
  }
}
