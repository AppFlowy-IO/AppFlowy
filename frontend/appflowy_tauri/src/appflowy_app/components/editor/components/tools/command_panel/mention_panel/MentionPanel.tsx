import React, { useRef } from 'react';
import {
  initialAnchorOrigin,
  initialTransformOrigin,
  PanelPopoverProps,
  PanelProps,
} from '$app/components/editor/components/tools/command_panel/Command.hooks';
import Popover from '@mui/material/Popover';

import MentionPanelContent from '$app/components/editor/components/tools/command_panel/mention_panel/MentionPanelContent';
import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';

export function MentionPanel({ anchorPosition, closePanel, searchText }: PanelProps) {
  const ref = useRef<HTMLDivElement>(null);

  const open = Boolean(anchorPosition);

  const {
    paperHeight,
    anchorPosition: newAnchorPosition,
    paperWidth,
    transformOrigin,
    anchorOrigin,
    isEntered,
  } = usePopoverAutoPosition({
    initialPaperWidth: 300,
    initialPaperHeight: 360,
    anchorPosition,
    initialTransformOrigin,
    initialAnchorOrigin,
    open,
  });

  return (
    <div ref={ref} className={'mention-panel'}>
      {open && (
        <Popover
          {...PanelPopoverProps}
          open={open && isEntered}
          anchorPosition={newAnchorPosition}
          anchorOrigin={anchorOrigin}
          transformOrigin={transformOrigin}
          onClose={() => closePanel(false)}
        >
          <MentionPanelContent
            width={paperWidth}
            maxHeight={paperHeight}
            closePanel={closePanel}
            searchText={searchText}
          />
        </Popover>
      )}
    </div>
  );
}

export default MentionPanel;
