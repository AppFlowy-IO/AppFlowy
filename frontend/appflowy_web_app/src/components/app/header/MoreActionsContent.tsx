import { Origins } from '@/components/_shared/popover';
import DeletePageConfirm from '@/components/app/view-actions/DeletePageConfirm';
import MovePagePopover from '@/components/app/view-actions/MovePagePopover';
import { Button } from '@mui/material';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import { ReactComponent as DuplicateIcon } from '@/assets/duplicate.svg';
import { ReactComponent as MoveToIcon } from '@/assets/move_to.svg';

function MoreActionsContent ({ itemClicked, viewId, movePopoverOrigins }: {
  itemClicked?: () => void;
  viewId: string;
  movePopoverOrigins: Origins
}) {
  const { t } = useTranslation();
  const [movePopoverAnchorEl, setMovePopoverAnchorEl] = useState<null | HTMLElement>(null);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);

  return (
    <div className={'flex flex-col gap-2'}>
      <Button
        size={'small'}
        className={'px-3 py-1 justify-start '}
        color={'inherit'}
        onClick={() => {
          //
        }}

        startIcon={<DuplicateIcon />}
      >{t('button.duplicate')}</Button>
      <Button
        size={'small'}
        className={'px-3 py-1 justify-start '}
        color={'inherit'}
        onClick={(e) => {
          setMovePopoverAnchorEl(e.currentTarget);
        }}

        startIcon={<MoveToIcon />}
      >{t('disclosureAction.moveTo')}</Button>
      <Button
        size={'small'}
        className={'px-3 py-1 justify-start  hover:text-function-error'}
        color={'inherit'}
        onClick={() => {
          setDeleteModalOpen(true);
        }}

        startIcon={<DeleteIcon />}
      >{t('button.delete')}</Button>
      <DeletePageConfirm
        open={deleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        viewId={viewId}
        onDeleted={itemClicked}
      />
      <MovePagePopover
        {...movePopoverOrigins}
        viewId={viewId}
        open={Boolean(movePopoverAnchorEl)}
        anchorEl={movePopoverAnchorEl}
        onClose={() => setMovePopoverAnchorEl(null)}
        onMoved={itemClicked}
      />
    </div>
  );
}

export default MoreActionsContent;