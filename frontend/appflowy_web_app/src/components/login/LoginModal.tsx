import React from 'react';
import { Dialog, IconButton } from '@mui/material';
import { Login } from './Login';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';

export function LoginModal({ redirectTo, open, onClose }: { redirectTo: string; open: boolean; onClose: () => void }) {
  return (
    <Dialog open={open} onClose={onClose}>
      <div className={'relative px-6'}>
        <Login redirectTo={redirectTo} />
        <div className={'absolute top-2 right-2'}>
          <IconButton color={'inherit'} onClick={onClose}>
            <CloseIcon className={'h-8 w-8'} />
          </IconButton>
        </div>
      </div>
    </Dialog>
  );
}
