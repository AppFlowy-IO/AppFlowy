import { getCurrentWorkspace } from 'src/application/services/js-services/session';
import { Button, Dialog, DialogActions, DialogContent, DialogContentText, DialogTitle } from '@mui/material';
import React from 'react';
import { useNavigate } from 'react-router-dom';

export function RecordNotFound({ open, title }: { open: boolean; title?: string }) {
  const navigate = useNavigate();

  return (
    <Dialog open={open}>
      <DialogTitle>Oops.. something went wrong</DialogTitle>
      <DialogContent>
        <DialogContentText id='alert-dialog-description'>
          {title ? title : 'The record you are looking for does not exist.'}
        </DialogContentText>
      </DialogContent>
      <DialogActions className={'flex w-full items-center justify-center'}>
        <Button
          onClick={async () => {
            const workspace = await getCurrentWorkspace();

            if (!workspace) return;
            navigate(`/view/${workspace.id}`);
          }}
        >
          Go back
        </Button>
      </DialogActions>
    </Dialog>
  );
}

export default RecordNotFound;
