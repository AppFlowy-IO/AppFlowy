import React from 'react';
import { SlashCommandPanel } from '$app/components/editor/components/tools/command_panel/slash_command_panel';
import { MentionPanel } from '$app/components/editor/components/tools/command_panel/mention_panel';
import { EditorCommand, useCommandPanel } from '$app/components/editor/components/tools/command_panel/Command.hooks';
import withErrorBoundary from '$app/components/_shared/error_boundary/withError';

function CommandPanel() {
  const { anchorPosition, searchText, openPanel, closePanel, command } = useCommandPanel();

  const Component = command === EditorCommand.SlashCommand ? SlashCommandPanel : MentionPanel;

  return (
    <Component closePanel={closePanel} searchText={searchText} openPanel={openPanel} anchorPosition={anchorPosition} />
  );
}

export default withErrorBoundary(CommandPanel);
