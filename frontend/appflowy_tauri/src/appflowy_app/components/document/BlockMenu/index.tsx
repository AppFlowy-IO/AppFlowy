import React, { useMemo } from 'react';
import { useBlockMenu } from './BlockMenu.hooks';
import DeleteIcon from '@mui/icons-material/Delete';
import AddIcon from '@mui/icons-material/Add';
import Button from '@mui/material/Button';

function BlockMenu({ open, onClose, nodeId }: { open: boolean; onClose: () => void; nodeId: string }) {
  const { ref, handleAddClick, handleDeleteClick, style } = useBlockMenu(nodeId, open);

  const btnList = useMemo(() => {
    return [
      {
        icon: <AddIcon />,
        onClick: async () => {
          await handleAddClick();
          onClose();
        },
        name: 'Add',
      },
      {
        icon: <DeleteIcon />,
        name: 'Delete',
        onClick: async () => {
          await handleDeleteClick();
          onClose();
        },
      },
    ];
  }, [handleDeleteClick, handleAddClick, onClose]);

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
        {btnList.map((btn) => (
          <Button
            key={btn.name}
            className='w-[100%]'
            variant={'text'}
            color={'inherit'}
            startIcon={btn.icon}
            onClick={btn.onClick}
            style={{ justifyContent: 'flex-start' }}
          >
            {btn.name}
          </Button>
        ))}
      </div>
    </div>
  ) : null;
}

export default React.memo(BlockMenu);
