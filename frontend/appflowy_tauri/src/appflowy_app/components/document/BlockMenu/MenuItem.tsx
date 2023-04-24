import React from 'react';
import DeleteIcon from '@mui/icons-material/Delete';
import AddIcon from '@mui/icons-material/Add';
import Button from '@mui/material/Button';
import { ActionType, useActions } from './MenuItem.hooks';

const icon: Record<ActionType, React.ReactNode> = {
  [ActionType.InsertAfter]: <AddIcon />,
  [ActionType.Remove]: <DeleteIcon />,
};

function MenuItem({ id, type, onClick }: { id: string; type: ActionType; onClick?: () => void }) {
  const action = useActions(id, type);
  return (
    <Button
      key={type}
      className='w-[100%]'
      variant={'text'}
      color={'inherit'}
      startIcon={icon[type]}
      onClick={() => {
        void action?.();
        onClick?.();
      }}
      style={{ justifyContent: 'flex-start' }}
    >
      {type}
    </Button>
  );
}

export default MenuItem;
