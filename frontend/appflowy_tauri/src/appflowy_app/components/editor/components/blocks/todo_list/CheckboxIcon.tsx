import React, { useCallback } from 'react';
import { TodoListNode } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';
import { useSlateStatic } from 'slate-react';
import { ReactComponent as CheckboxCheckSvg } from '$app/assets/database/checkbox-check.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$app/assets/database/checkbox-uncheck.svg';

function CheckboxIcon({ block, className }: { block: TodoListNode; className: string }) {
  const editor = useSlateStatic();
  const { checked } = block.data;

  const toggleTodo = useCallback(() => {
    CustomEditor.toggleTodo(editor, block);
  }, [editor, block]);

  return (
    <span
      data-playwright-selected={false}
      contentEditable={false}
      onClick={toggleTodo}
      draggable={false}
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      className={`${className} cursor-pointer pr-1 text-xl text-fill-default`}
    >
      {checked ? <CheckboxCheckSvg /> : <CheckboxUncheckSvg />}
    </span>
  );
}

export default CheckboxIcon;
