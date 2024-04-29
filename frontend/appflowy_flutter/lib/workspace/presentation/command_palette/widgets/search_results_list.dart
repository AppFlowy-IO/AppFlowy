import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_result_tile.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.trash,
    required this.results,
  });

  final List<TrashPB> trash;
  final List<SearchResultPB> results;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemCount: results.length + 1,
      itemBuilder: (_, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8) +
                const EdgeInsets.only(left: 16),
            child: FlowyText(
              LocaleKeys.commandPalette_bestMatches.tr(),
            ),
          );
        }

        final result = results[index - 1];
        return SearchResultTile(
          result: result,
          onSelected: () => FlowyOverlay.pop(context),
          isTrashed: trash.any((t) => t.id == result.viewId),
        );
      },
    );
  }
}
