import React, { useRef } from 'react';
import { PanelPopoverProps, usePanel } from '$app/components/editor/components/tools/command_panel/usePanel.hooks';
import Popover from '@mui/material/Popover';

import MentionPanelContent from '$app/components/editor/components/tools/command_panel/mention_panel/MentionPanelContent';

export function MentionPanel() {
  const ref = useRef<HTMLDivElement>(null);
  const { anchorPosition, closePanel, searchText } = usePanel(ref);

  const open = Boolean(anchorPosition);

  return (
    <div ref={ref} className={'mention-panel'}>
      {open && (
        <Popover {...PanelPopoverProps} open={open} anchorPosition={anchorPosition} onClose={() => closePanel(false)}>
          <MentionPanelContent closePanel={closePanel} searchText={searchText} />
        </Popover>
      )}
    </div>
  );
}

export default MentionPanel;
