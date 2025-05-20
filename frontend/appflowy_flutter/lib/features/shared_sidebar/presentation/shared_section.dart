import 'package:appflowy/features/shared_sidebar/data/rust_share_pagers_repository.dart';
import 'package:appflowy/features/shared_sidebar/logic/shared_sidebar_bloc.dart';
import 'package:appflowy/features/shared_sidebar/presentation/widgets/refresh_button.dart';
import 'package:appflowy/features/shared_sidebar/presentation/widgets/shared_pages_list.dart';
import 'package:appflowy/features/shared_sidebar/presentation/widgets/shared_section_error.dart';
import 'package:appflowy/features/shared_sidebar/presentation/widgets/shared_section_header.dart';
import 'package:appflowy/features/shared_sidebar/presentation/widgets/shared_section_loading.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedSection extends StatelessWidget {
  const SharedSection({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SharedSidebarBloc(
        workspaceId: workspaceId,
        repository: RustSharePagesRepository(),
      )..add(const SharedSidebarEvent.init()),
      child: BlocBuilder<SharedSidebarBloc, SharedSidebarState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const SharedSectionLoading();
          }

          if (state.errorMessage.isNotEmpty) {
            return SharedSectionError(errorMessage: state.errorMessage);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shared header
              const SharedSectionHeader(),

              // Shared pages list
              SharedPagesList(sharedPages: state.sharedPages),

              // Refresh button, for debugging only
              if (kDebugMode)
                RefreshSharedSectionButton(
                  onTap: () {
                    context.read<SharedSidebarBloc>().add(
                          const SharedSidebarEvent.refresh(),
                        );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
