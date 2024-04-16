import { TodoListNode } from '@/components/editor/editor.type';
import React from 'react';
import { ReactComponent as CheckboxCheckSvg } from '@/assets/database/checkbox-check.svg';
import { ReactComponent as CheckboxUncheckSvg } from '@/assets/database/checkbox-uncheck.svg';

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
      className={`${className} cursor-pointer pr-1 text-xl text-fill-default`}
    >
      {checked ? <CheckboxCheckSvg /> : <CheckboxUncheckSvg />}
    </span>
  );
}

export default CheckboxIcon;
