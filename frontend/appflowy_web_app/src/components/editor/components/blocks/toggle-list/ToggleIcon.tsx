import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { ToggleListNode } from '@/components/editor/editor.type';
import React, { useCallback } from 'react';
import { ReactComponent as ExpandSvg } from '$icons/16x/drop_menu_show.svg';
import { useReadOnly, useSlateStatic } from 'slate-react';
import { Element } from 'slate';

function ToggleIcon({ block, className }: { block: ToggleListNode; className: string }) {
  const { collapsed } = block.data;
  const editor = useSlateStatic();
  const readOnly = useReadOnly() || editor.isElementReadOnly(block as unknown as Element);

  const handleClick = useCallback((e: React.MouseEvent) => {
    if (readOnly) {
      return;
    }

    e.stopPropagation();
    e.preventDefault();
    CustomEditor.toggleToggleList(editor as YjsEditor, block.blockId);
  }, [block.blockId, editor, readOnly]);

  return (
    <span
      onClick={handleClick}
      data-playwright-selected={false}
      contentEditable={false}
      draggable={false}
      onMouseDown={e => {
        e.preventDefault();
      }}
      className={`${className} ${readOnly ? '' : 'cursor-pointer hover:text-fill-default'} pr-1 text-xl h-full`}
    >
      {collapsed ? <ExpandSvg className={'-rotate-90 transform'}/> : <ExpandSvg/>}
    </span>
  );
}

export default ToggleIcon;
