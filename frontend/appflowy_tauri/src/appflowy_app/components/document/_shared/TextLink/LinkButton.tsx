import React from 'react';
import Button from '@mui/material/Button';
import { DeleteOutline } from '@mui/icons-material';

function LinkButton({ icon, title, onClick }: { icon: React.ReactNode; title: string; onClick: () => void }) {
  return (
    <div className={'pt-1'}>
      <Button
        className={'w-[100%]'}
        style={{
          justifyContent: 'flex-start',
        }}
        startIcon={icon}
        onClick={onClick}
      >
        {title}
      </Button>
    </div>
  );
}

export default LinkButton;
