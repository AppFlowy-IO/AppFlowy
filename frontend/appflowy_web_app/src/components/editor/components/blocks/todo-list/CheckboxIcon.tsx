import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { TodoListNode } from '@/components/editor/editor.type';
import React, { useCallback } from 'react';
import { ReactComponent as CheckboxCheckSvg } from '$icons/16x/check_filled.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$icons/16x/uncheck.svg';
import { useReadOnly, useSlateStatic } from 'slate-react';
import { Element } from 'slate';

function CheckboxIcon({ block, className }: { block: TodoListNode; className: string }) {
  const { checked } = block.data;
  const editor = useSlateStatic();
  const readOnly = useReadOnly() || editor.isElementReadOnly(block as unknown as Element);

  const handleClick = useCallback((e: React.MouseEvent) => {
    if (readOnly) {
      return;
    }

    e.stopPropagation();
    e.preventDefault();
    editor.collapse({
      edge: 'end',
    });

    CustomEditor.toggleTodoList(editor as YjsEditor, block.blockId, e.shiftKey);
  }, [block, editor, readOnly]);

  return (
    <span
      onClick={handleClick}
      data-playwright-selected={false}
      contentEditable={false}
      draggable={false}
      onMouseDown={e => {
        e.preventDefault();
      }}
      className={`${className} ${readOnly ? '' : 'cursor-pointer hover:text-fill-default'} pr-1 text-xl`}
    >
      {checked ? <CheckboxCheckSvg/> : <CheckboxUncheckSvg/>}
    </span>
  );
}

export default CheckboxIcon;
