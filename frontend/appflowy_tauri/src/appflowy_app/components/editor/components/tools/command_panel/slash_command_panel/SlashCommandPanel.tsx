import React, { useRef } from 'react';
import { PanelPopoverProps, usePanel } from '$app/components/editor/components/tools/command_panel/usePanel.hooks';
import Popover from '@mui/material/Popover';
import SlashCommandPanelContent from '$app/components/editor/components/tools/command_panel/slash_command_panel/SlashCommandPanelContent';
import { useSlate } from 'slate-react';

export function SlashCommandPanel() {
  const ref = useRef<HTMLDivElement>(null);
  const editor = useSlate();
  const { anchorPosition, closePanel, searchText } = usePanel(ref);

  const open = Boolean(anchorPosition);

  return (
    <div ref={ref} className={'slash-command-panel'}>
      {open && (
        <Popover
          {...PanelPopoverProps}
          open={open}
          anchorPosition={anchorPosition}
          onClose={() => {
            const selection = editor.selection;

            closePanel(false);

            if (selection) {
              editor.select(selection);
            }
          }}
        >
          <SlashCommandPanelContent closePanel={closePanel} searchText={searchText} />
        </Popover>
      )}
    </div>
  );
}

export default SlashCommandPanel;
