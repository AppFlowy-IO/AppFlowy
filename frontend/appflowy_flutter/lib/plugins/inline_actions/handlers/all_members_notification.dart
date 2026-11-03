import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/service_handler.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AllMembersNotificationService extends InlineActionsDelegate {
  AllMembersNotificationService(this.context);

  final BuildContext context;

  static const _keywords = ['all', 'everyone', 'members', 'notify'];

  List<WorkspaceMemberPB>? _members;
  String? _workspaceId;

  @override
  Future<InlineActionsResult> search([
    String? search,
  ]) async {
    final workspace =
        context.read<UserWorkspaceBloc?>()?.state.currentWorkspace;
    if (workspace == null ||
        workspace.workspaceType == WorkspaceTypePB.LocalW) {
      return InlineActionsResult(title: 'Notifications', results: const []);
    }

    if (_workspaceId != workspace.workspaceId || _members == null) {
      _workspaceId = workspace.workspaceId;
      _members = await _fetchWorkspaceMembers(workspace.workspaceId);
    }

    final members = _members ?? const <WorkspaceMemberPB>[];
    if (members.isEmpty) {
      return InlineActionsResult(title: 'Notifications', results: const []);
    }

    if (!_matchesSearch(search)) {
      return InlineActionsResult(title: 'Notifications', results: const []);
    }

    return InlineActionsResult(
      title: 'Notifications',
      startsWithKeywords: _keywords,
      results: [
        InlineActionsMenuItem(
          label: '@all',
          keywords: _keywords,
          iconBuilder: (_) => const FlowySvg(
            FlowySvgs.settings_members_m,
            size: Size.square(16),
          ),
          onSelected: (context, editorState, menuService, replace) =>
              _insertMention(
            editorState,
            workspace.workspaceId,
            members,
            replace.$1,
            replace.$2,
          ),
        ),
      ],
    );
  }

  bool _matchesSearch(String? search) {
    if (search == null || search.isEmpty) {
      return true;
    }

    final normalized = search.toLowerCase();
    return _keywords.any((keyword) => keyword.contains(normalized));
  }

  Future<List<WorkspaceMemberPB>> _fetchWorkspaceMembers(
    String workspaceId,
  ) async {
    final userProfile = context.read<UserWorkspaceBloc?>()?.state.userProfile;
    if (userProfile == null) {
      return const [];
    }

    final result = await UserBackendService(
      userId: userProfile.id,
    ).getWorkspaceMembers(workspaceId);

    return result.fold(
      (success) => success.items,
      (_) => const [],
    );
  }

  Future<void> _insertMention(
    EditorState editorState,
    String workspaceId,
    List<WorkspaceMemberPB> members,
    int start,
    int end,
  ) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final node = editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }

    final memberEmails = members
        .map((member) => member.email)
        .where((email) => email.isNotEmpty)
        .toList();
    if (memberEmails.isEmpty) {
      return;
    }

    final transaction = editorState.transaction
      ..replaceText(
        node,
        start,
        end,
        MentionBlockKeys.mentionChar,
        attributes: MentionBlockKeys.buildMentionAllMembersAttributes(
          workspaceId: workspaceId,
          memberEmails: memberEmails,
        ),
      );

    await editorState.apply(transaction);
  }
}
