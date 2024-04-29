import { ToggleListNode } from '@/components/editor/editor.type';
import React from 'react';
import { ReactComponent as RightSvg } from '@/assets/more.svg';

function ToggleIcon({ block, className }: { block: ToggleListNode; className: string }) {
  const { collapsed } = block.data;

  return (
    <span
      data-playwright-selected={false}
      contentEditable={false}
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      className={`${className} cursor-pointer pr-1 text-xl hover:text-fill-default`}
    >
      {collapsed ? <RightSvg /> : <RightSvg className={'rotate-90 transform'} />}
    </span>
  );
}

export default ToggleIcon;
