import React, { useState } from 'react';
import { TextCell } from '$app/components/database/application';
import { IconButton } from '@mui/material';
import { ReactComponent as OpenIcon } from '$app/assets/open.svg';

const ExpandCellModal = React.lazy(() => import('$app/components/database/components/cell/expand_type/ExpandCellModal'));

interface Props {
  cell: TextCell;
  visible?: boolean;
  documentId?: string;
  icon?: string;
}
function ExpandButton({ cell, documentId, icon, visible }: Props) {
  const [open, setOpen] = useState(false);

  const onClose = () => {
    setOpen(false);
  };

  return (
    <>
      {visible && (
        <div className={`mr-4 flex items-center justify-center`}>
          <IconButton onClick={() => setOpen(true)} className={'h-6 w-6 text-sm'}>
            <OpenIcon />
          </IconButton>
        </div>
      )}

      {open && documentId && (
        <ExpandCellModal documentId={documentId} icon={icon} cell={cell} open={open} onClose={onClose} />
      )}
    </>
  );
}

export default ExpandButton;
