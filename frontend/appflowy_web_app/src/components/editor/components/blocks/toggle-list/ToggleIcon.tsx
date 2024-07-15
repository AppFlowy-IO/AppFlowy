import { ToggleListNode } from '@/components/editor/editor.type';
import React from 'react';
import { ReactComponent as ExpandSvg } from '$icons/16x/drop_menu_show.svg';

function ToggleIcon({ block, className }: { block: ToggleListNode; className: string }) {
  const { collapsed } = block.data;

  return (
    <span
      data-playwright-selected={false}
      contentEditable={false}
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      className={`${className} pr-1 text-xl hover:text-fill-default`}
    >
      {collapsed ? <ExpandSvg className={'-rotate-90 transform'} /> : <ExpandSvg />}
    </span>
  );
}

export default ToggleIcon;
