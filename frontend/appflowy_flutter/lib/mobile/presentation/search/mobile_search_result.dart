import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_results_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileSearchResult extends StatelessWidget {
  const MobileSearchResult({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<CommandPaletteBloc>().state;
    return SearchResultList(
      trash: state.trash,
      resultItems: state.combinedResponseItems.values.toList(),
      resultSummaries: state.resultSummaries,
    );
  }
}
