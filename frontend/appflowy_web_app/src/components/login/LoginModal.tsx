import React from 'react';
import { Dialog, IconButton } from '@mui/material';
import { Login } from './Login';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';

function LoginModal({ redirectTo, open, onClose }: { redirectTo: string; open: boolean; onClose: () => void }) {
  return (
    <Dialog open={open} onClose={onClose}>
      <div className={'relative px-6'}>
        <Login redirectTo={redirectTo} />
        <div className={'absolute top-2 right-2'}>
          <IconButton size={'small'} color={'inherit'} className={'h-6 w-6'} onClick={onClose}>
            <CloseIcon className={'h-4 w-4'} />
          </IconButton>
        </div>
      </div>
    </Dialog>
  );
}

export default LoginModal;
