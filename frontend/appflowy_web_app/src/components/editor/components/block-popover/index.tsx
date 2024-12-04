import { YjsEditor } from '@/application/slate-yjs';
import { findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';
import { BlockType } from '@/application/types';
import { Origins, Popover } from '@/components/_shared/popover';
import { usePopoverContext } from '@/components/editor/components/block-popover/BlockPopoverContext';
import FileBlockPopoverContent from '@/components/editor/components/block-popover/FileBlockPopoverContent';
import ImageBlockPopoverContent from '@/components/editor/components/block-popover/ImageBlockPopoverContent';
import { useEditorContext } from '@/components/editor/EditorContext';
import { debounce } from 'lodash-es';
import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import { ReactEditor, useSlateStatic } from 'slate-react';
import MathEquationPopoverContent from './MathEquationPopoverContent';

const defaultOrigins: Origins = {
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'center',
  },
  transformOrigin: {
    vertical: 'top',
    horizontal: 'center',
  },
};

function BlockPopover () {
  const {
    open,
    anchorEl,
    close,
    type,
    blockId,
  } = usePopoverContext();
  const { setSelectedBlockIds } = useEditorContext();
  const editor = useSlateStatic() as YjsEditor;
  const [origins, setOrigins] = React.useState<Origins>(defaultOrigins);

  const handleClose = useCallback(() => {
    window.getSelection()?.removeAllRanges();
    if (!blockId) return;

    const [, path] = findSlateEntryByBlockId(editor, blockId);

    editor.select(editor.start(path));
    ReactEditor.focus(editor);
    close();
  }, [blockId, close, editor]);

  const content = useMemo(() => {
    if (!blockId) return;
    switch (type) {
      case BlockType.FileBlock:
        return <FileBlockPopoverContent
          blockId={blockId}
          onClose={handleClose}
        />;
      case BlockType.ImageBlock:
        return <ImageBlockPopoverContent
          blockId={blockId}
          onClose={handleClose}
        />;
      case BlockType.EquationBlock:
        return <MathEquationPopoverContent
          blockId={blockId}
          onClose={handleClose}
        />;
      default:
        return null;
    }
  }, [type, blockId, handleClose]);

  const paperRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (blockId) {

      setSelectedBlockIds?.([blockId]);
    } else {
      setSelectedBlockIds?.([]);
    }
  }, [blockId, setSelectedBlockIds]);

  const debouncePosition = useMemo(() => {
    return debounce(() => {
      if (!anchorEl || !paperRef.current) return;

      const rect = anchorEl.getBoundingClientRect();
      const paperRect = paperRef.current.getBoundingClientRect();

      if (rect.bottom + paperRect.height > window.innerHeight) {
        setOrigins({
          anchorOrigin: {
            vertical: -8,
            horizontal: 'center',
          },
          transformOrigin: {
            vertical: 'bottom',
            horizontal: 'center',
          },
        });
        return;
      }

    }, 50);
  }, [anchorEl]);

  useEffect(() => {
    if (!open) return;
    editor.deselect();
  }, [open, editor]);

  return <Popover
    open={open}
    onClose={handleClose}
    anchorEl={anchorEl}
    adjustOrigins={false}
    slotProps={{
      paper: {
        ref: paperRef,
      },
    }}
    onTransitionEnter={() => {
      setOrigins(defaultOrigins);
    }}
    onTransitionEnd={debouncePosition}
    {...origins}
    disableRestoreFocus={true}
  >
    {content}
  </Popover>;
}

export default BlockPopover;