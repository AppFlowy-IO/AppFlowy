import React, { useState } from 'react';
import { DialogProps, IconButton, Portal } from '@mui/material';
import DialogContent from '@mui/material/DialogContent';
import Dialog from '@mui/material/Dialog';
import { ReactComponent as DetailsIcon } from '$app/assets/details.svg';
import RecordActions from '$app/components/database/components/edit_record/RecordActions';
import EditRecord from '$app/components/database/components/edit_record/EditRecord';

interface Props extends DialogProps {
  rowId: string;
}

function ExpandRecordModal({ open, onClose, rowId }: Props) {
  const [detailAnchorEl, setDetailAnchorEl] = useState<HTMLButtonElement | null>(null);

  return (
    <Portal>
      <Dialog
        disableAutoFocus={true}
        keepMounted={false}
        onMouseDown={(e) => e.stopPropagation()}
        open={open}
        onClose={onClose}
        PaperProps={{
          className: 'h-[calc(100%-144px)] w-[80%] max-w-[960px]',
        }}
      >
        <IconButton
          aria-label='close'
          className={'absolute right-[8px] top-[8px] text-text-caption'}
          onClick={(e) => {
            setDetailAnchorEl(e.currentTarget);
          }}
        >
          <DetailsIcon />
        </IconButton>
        <DialogContent>
          <EditRecord rowId={rowId} />
        </DialogContent>
      </Dialog>
      <RecordActions
        anchorEl={detailAnchorEl}
        rowId={rowId}
        open={!!detailAnchorEl}
        onClose={() => setDetailAnchorEl(null)}
      />
    </Portal>
  );
}

export default ExpandRecordModal;
