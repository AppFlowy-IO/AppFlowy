import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/transaction_handler/editor_transaction_handler.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

/// The data used to handle transactions for mentions.
///
/// [Node] is the block node.
/// [Map] is the data of the mention block.
/// [int] is the index of the mention block in the list of deltas (after transaction apply).
///
typedef MentionBlockData = (Node, Map<String, dynamic>, int);

abstract class MentionTransactionHandler
    extends EditorTransactionHandler<MentionBlockData> {
  const MentionTransactionHandler({
    required this.subType,
  })
      : super(type: MentionBlockKeys.mention, livesInDelta: true);

  final String subType;

  MentionType get mentionType => MentionType.fromString(subType);
}
