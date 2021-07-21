import 'package:app_flowy/home/application/app/app_bloc.dart';
import 'package:app_flowy/startup/startup.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:expandable/expandable.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';

import 'app_widget.dart';

class AppList extends StatelessWidget {
  const AppList({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<AppBloc>()..add(const AppEvent.initial()),
        ),
      ],
      child: BlocBuilder<AppBloc, AppState>(
        buildWhen: (p, c) => p.apps != c.apps,
        builder: (context, state) {
          Log.info('AppList build');
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          return state.apps.fold(
            () => state.successOrFailure.fold(
              (_) => const Text('You have no apps, create one?'),
              (error) => FlowyErrorPage(error.toString()),
            ),
            (apps) => _buildBody(apps),
          );
        },
      ),
    );
  }

  Widget _buildBody(List<App> apps) {
    return ExpandableTheme(
        data: const ExpandableThemeData(
          iconColor: Colors.blue,
          useInkWell: true,
        ),
        child: Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: apps.map((app) => AppWidget(app)).toList(),
          ),
        ));
  }
}
