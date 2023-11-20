import React, { useState } from 'react';
import { DialogProps, IconButton } from '@mui/material';
import DialogContent from '@mui/material/DialogContent';
import Dialog from '@mui/material/Dialog';
import { TextCell } from '$app/components/database/application';
import { ReactComponent as DetailsIcon } from '$app/assets/details.svg';
import RecordActions from '$app/components/database/components/edit_record/RecordActions';
import EditRecord from '$app/components/database/components/edit_record/EditRecord';

interface Props extends DialogProps {
  cell: TextCell;
  documentId: string;
  icon?: string;
}

function ExpandCellModal({ open, onClose, cell, documentId, icon }: Props) {
  const [detailAnchorEl, setDetailAnchorEl] = useState<HTMLButtonElement | null>(null);

  return (
    <>
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
          <EditRecord cell={cell} documentId={documentId} icon={icon} />
        </DialogContent>
      </Dialog>
      <RecordActions
        anchorEl={detailAnchorEl}
        cell={cell}
        open={!!detailAnchorEl}
        onClose={() => setDetailAnchorEl(null)}
      />
    </>
  );
}

export default ExpandCellModal;
