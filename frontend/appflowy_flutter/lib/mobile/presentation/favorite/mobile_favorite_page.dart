import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileFavoriteScreen extends StatefulWidget {
  static const routeName = '/favorite';

  const MobileFavoriteScreen({
    super.key,
    required this.id,
  });

  /// view id
  final String id;

  @override
  State<MobileFavoriteScreen> createState() => _MobileFavoriteScreenState();
}

class _MobileFavoriteScreenState extends State<MobileFavoriteScreen> {
  late final Future<Either<ViewPB, FlowyError>> future;

  @override
  void initState() {
    super.initState();

    future = ViewBackendService.getView(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: future,
          builder: (context, state) {
            if (state.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (!state.hasData) {
              // FIXME: handle the error
              return const Center(
                child: FlowyText('No data'),
              );
            }
            return state.data!.fold((view) {
              final widget =
                  view.plugin().widgetBuilder.buildWidget(shrinkWrap: false);
              return Scaffold(
                appBar: AppBar(
                  titleSpacing: 0,
                  title: FlowyText(
                    view.name,
                    fontSize: 14.0,
                  ),
                  leading: BackButton(
                    onPressed: () => context.pop(),
                  ),
                ),
                body: widget,
              );
            }, (error) {
              return Center(
                child: FlowyText(error.toString()),
              );
            });
          },
        ),
      ),
    );
  }
}
