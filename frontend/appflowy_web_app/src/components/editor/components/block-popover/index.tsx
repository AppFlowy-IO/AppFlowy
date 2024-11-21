import { YjsEditor } from '@/application/slate-yjs';
import { findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';
import { BlockType } from '@/application/types';
import { Popover } from '@/components/_shared/popover';
import { usePopoverContext } from '@/components/editor/components/block-popover/BlockPopoverContext';
import FileBlockPopoverContent from '@/components/editor/components/block-popover/FileBlockPopoverContent';
import ImageBlockPopoverContent from '@/components/editor/components/block-popover/ImageBlockPopoverContent';
import { useEditorContext } from '@/components/editor/EditorContext';
import React, { useCallback, useEffect, useMemo } from 'react';
import { ReactEditor, useSlateStatic } from 'slate-react';
import MathEquationPopoverContent from './MathEquationPopoverContent';

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

  useEffect(() => {
    if (blockId) {
      setSelectedBlockIds?.([blockId]);
    } else {
      setSelectedBlockIds?.([]);
    }
  }, [blockId, setSelectedBlockIds]);

  return <Popover
    open={open}
    onClose={handleClose}
    anchorEl={anchorEl}
    transformOrigin={{
      vertical: 'top',
      horizontal: 'center',
    }}
    anchorOrigin={{
      vertical: 'bottom',
      horizontal: 'center',
    }}
    disableRestoreFocus={true}
  >
    {content}
  </Popover>;
}

export default BlockPopover;