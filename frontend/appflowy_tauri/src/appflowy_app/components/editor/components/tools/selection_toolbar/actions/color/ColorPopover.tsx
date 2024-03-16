import React, { useCallback } from 'react';
import { PopoverNoBackdropProps } from '$app/components/editor/components/tools/popover';
import { ColorPicker } from '$app/components/editor/components/tools/_shared';
import { Popover } from '@mui/material';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import { EditorMarkFormat } from '$app/application/document/document.types';
import { addMark, removeMark } from 'slate';
import { useSlateStatic } from 'slate-react';
import { DebouncedFunc } from 'lodash-es/debounce';
import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';

const initialOrigin: {
  transformOrigin?: PopoverOrigin;
  anchorOrigin?: PopoverOrigin;
} = {
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'center',
  },
  transformOrigin: {
    vertical: 'top',
    horizontal: 'center',
  },
};

function ColorPopover({
  open,
  anchorEl,
  debounceClose,
}: {
  open: boolean;
  onOpen: () => void;
  anchorEl: HTMLButtonElement | null;
  debounceClose: DebouncedFunc<() => void>;
}) {
  const editor = useSlateStatic();
  const handleChange = useCallback(
    (format: EditorMarkFormat.FontColor | EditorMarkFormat.BgColor, color: string) => {
      if (color) {
        addMark(editor, format, color);
      } else {
        removeMark(editor, format);
      }
    },
    [editor]
  );

  const { paperHeight, transformOrigin, anchorOrigin, isEntered } = usePopoverAutoPosition({
    initialPaperWidth: 200,
    initialPaperHeight: 420,
    anchorEl,
    initialAnchorOrigin: initialOrigin.anchorOrigin,
    initialTransformOrigin: initialOrigin.transformOrigin,
    open,
  });

  return (
    <Popover
      {...PopoverNoBackdropProps}
      open={open && isEntered}
      anchorEl={anchorEl}
      onClose={debounceClose}
      PaperProps={{
        ...PopoverNoBackdropProps.PaperProps,
        className: 'w-[200px] overflow-hidden',
        style: {
          ...PopoverNoBackdropProps.PaperProps?.style,
          height: paperHeight,
        },
      }}
      anchorOrigin={anchorOrigin}
      transformOrigin={transformOrigin}
      onKeyDown={(e) => {
        e.stopPropagation();
        if (e.key === 'Escape') {
          debounceClose();
        }
      }}
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      onMouseEnter={() => {
        debounceClose.cancel();
      }}
      onMouseLeave={debounceClose}
    >
      <ColorPicker disableFocus={true} onEscape={debounceClose} onChange={handleChange} />
    </Popover>
  );
}

export default ColorPopover;
