import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/workspace/workspace_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void createWorkspace(BuildContext context) {
  context.read<WorkspaceBloc>().add(
        WorkspaceEvent.createWorkspace(
          LocaleKeys.workspace_hint.tr(),
          "",
        ),
      );
}
