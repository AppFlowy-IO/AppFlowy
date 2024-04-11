import React, { useCallback, useRef } from 'react';
import {
  initialAnchorOrigin,
  initialTransformOrigin,
  PanelPopoverProps,
  PanelProps,
} from '$app/components/editor/components/tools/command_panel/Command.hooks';
import Popover from '@mui/material/Popover';
import SlashCommandPanelContent from '$app/components/editor/components/tools/command_panel/slash_command_panel/SlashCommandPanelContent';
import { useSlate } from 'slate-react';
import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';

export function SlashCommandPanel({ anchorPosition, closePanel, searchText }: PanelProps) {
  const ref = useRef<HTMLDivElement>(null);
  const editor = useSlate();

  const open = Boolean(anchorPosition);

  const handleClose = useCallback(
    (deleteText?: boolean) => {
      closePanel(deleteText);
    },
    [closePanel]
  );

  const {
    paperHeight,
    paperWidth,
    anchorPosition: newAnchorPosition,
    transformOrigin,
    anchorOrigin,
    isEntered,
  } = usePopoverAutoPosition({
    initialPaperWidth: 220,
    initialPaperHeight: 360,
    anchorPosition,
    initialTransformOrigin,
    initialAnchorOrigin,
    open,
  });

  return (
    <div ref={ref} className={'slash-command-panel'}>
      {open && (
        <Popover
          {...PanelPopoverProps}
          open={open && isEntered}
          anchorPosition={newAnchorPosition}
          anchorOrigin={anchorOrigin}
          transformOrigin={transformOrigin}
          onClose={() => {
            const selection = editor.selection;

            handleClose(false);

            if (selection) {
              editor.select(selection);
            }
          }}
        >
          <SlashCommandPanelContent
            width={paperWidth}
            maxHeight={paperHeight}
            closePanel={handleClose}
            searchText={searchText}
          />
        </Popover>
      )}
    </div>
  );
}

export default SlashCommandPanel;
