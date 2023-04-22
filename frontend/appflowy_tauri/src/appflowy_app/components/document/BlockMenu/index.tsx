import React from 'react';
import { useBlockMenu } from './BlockMenu.hooks';
import MenuItem from './MenuItem';
import { ActionType } from '$app/components/document/BlockMenu/MenuItem.hooks';

function BlockMenu({ open, onClose, nodeId }: { open: boolean; onClose: () => void; nodeId: string }) {
  const { ref, style } = useBlockMenu(nodeId, open);

  return open ? (
    <div
      ref={ref}
      className='appflowy-block-menu-overlay z-1 fixed inset-0 overflow-hidden'
      onScrollCapture={(e) => {
        // prevent scrolling of the document when menu is open
        e.stopPropagation();
      }}
      onMouseDown={(e) => {
        // prevent menu from taking focus away from editor
        e.preventDefault();
        e.stopPropagation();
      }}
      onClick={(e) => {
        e.stopPropagation();
        onClose();
      }}
    >
      <div
        className='z-99 absolute flex w-[200px] translate-x-[-100%] translate-y-[32px] transform flex-col items-start justify-items-start rounded bg-white p-4 shadow'
        style={style}
        onClick={(e) => {
          // prevent menu close when clicking on menu
          e.stopPropagation();
        }}
      >
        <MenuItem id={nodeId} type={ActionType.InsertAfter} />
        <MenuItem id={nodeId} type={ActionType.Remove} onClick={onClose} />
      </div>
    </div>
  ) : null;
}

export default React.memo(BlockMenu);
