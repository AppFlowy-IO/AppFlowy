import { TodoListNode } from '@/components/editor/editor.type';
import React from 'react';
import { ReactComponent as CheckboxCheckSvg } from '$icons/16x/check_filled.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$icons/16x/uncheck.svg';

function CheckboxIcon({ block, className }: { block: TodoListNode; className: string }) {
  const { checked } = block.data;

  return (
    <span
      data-playwright-selected={false}
      contentEditable={false}
      draggable={false}
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      className={`${className} pr-1 text-xl text-fill-default`}
    >
      {checked ? <CheckboxCheckSvg /> : <CheckboxUncheckSvg />}
    </span>
  );
}

export default CheckboxIcon;
