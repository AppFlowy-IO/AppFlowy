import { YjsEditor } from '@/application/slate-yjs';
import { findSlateEntryByBlockId } from '@/application/slate-yjs/utils/slateUtils';
import { BlockType } from '@/application/types';
import { Popover } from '@/components/_shared/popover';
import { usePopoverContext } from '@/components/editor/components/block-popover/BlockPopoverContext';
import FileBlockPopoverContent from '@/components/editor/components/block-popover/FileBlockPopoverContent';
import ImageBlockPopoverContent from '@/components/editor/components/block-popover/ImageBlockPopoverContent';
import { useEditorContext } from '@/components/editor/EditorContext';
import React, { useEffect, useMemo } from 'react';
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
  const { setSelectedBlockId } = useEditorContext();
  const editor = useSlateStatic() as YjsEditor;

  const content = useMemo(() => {
    if (!blockId) return;
    switch (type) {
      case BlockType.FileBlock:
        return <FileBlockPopoverContent blockId={blockId} />;
      case BlockType.ImageBlock:
        return <ImageBlockPopoverContent blockId={blockId} />;
      case BlockType.EquationBlock:
        return <MathEquationPopoverContent blockId={blockId} />;
      default:
        return null;
    }
  }, [type, blockId]);

  useEffect(() => {
    setSelectedBlockId?.(blockId);
  }, [blockId, setSelectedBlockId]);

  return <Popover
    open={open}
    onClose={() => {
      window.getSelection()?.removeAllRanges();
      if (!blockId) return;

      const [, path] = findSlateEntryByBlockId(editor, blockId);

      editor.select(editor.start(path));
      ReactEditor.focus(editor);
      close();
    }}
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