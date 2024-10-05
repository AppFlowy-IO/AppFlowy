import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { TodoListNode } from '@/components/editor/editor.type';
import { debounce } from 'lodash-es';
import React, { useCallback, useMemo } from 'react';
import { ReactComponent as CheckboxCheckSvg } from '$icons/16x/check_filled.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$icons/16x/uncheck.svg';
import { useReadOnly, useSlateStatic } from 'slate-react';

function CheckboxIcon ({ block, className }: { block: TodoListNode; className: string }) {
  const { checked } = block.data;
  const editor = useSlateStatic();
  const readOnly = useReadOnly();

  const toggleChecked = useMemo(() => {
    if (readOnly) {
      return;
    }

    return debounce(() => {
      CustomEditor.toggleTodoList(editor as YjsEditor, block.blockId);
    }, 100);
  }, [readOnly, editor, block.blockId]);

  const handleClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    e.preventDefault();
    toggleChecked?.();
  }, [toggleChecked]);

  return (
    <span
      onClick={handleClick}
      data-playwright-selected={false}
      contentEditable={false}
      draggable={false}
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      className={`${className} ${readOnly ? '' : 'cursor-pointer hover:text-fill-default'} pr-1 text-xl`}
    >
      {checked ? <CheckboxCheckSvg /> : <CheckboxUncheckSvg />}
    </span>
  );
}

export default CheckboxIcon;
