import React, { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { IconButton } from '@mui/material';
import ButtonPopoverList from '$app/components/_shared/button_menu/ButtonMenu';

import { ReactComponent as DetailsSvg } from '$app/assets/details.svg';
import { ReactComponent as EditSvg } from '$app/assets/edit.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { ReactComponent as TrashSvg } from '$app/assets/delete.svg';

import RenameDialog from './RenameDialog';
import { Page } from '$app_reducers/pages/slice';
import DeleteDialog from '$app/components/layout/nested_page/DeleteDialog';

function MoreButton({
  isVisible,
  onDelete,
  onDuplicate,
  onRename,
  page,
}: {
  isVisible: boolean;
  onDelete: () => Promise<void>;
  onDuplicate: () => Promise<void>;
  onRename: (newName: string) => Promise<void>;
  page: Page;
}) {
  const [renameDialogOpen, setRenameDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);

  const { t } = useTranslation();
  const options = useMemo(
    () => [
      {
        label: t('disclosureAction.rename'),
        key: 'rename',
        icon: (
          <div className={'h-5 w-5'}>
            <EditSvg />
          </div>
        ),
        onClick: () => {
          setRenameDialogOpen(true);
        },
      },
      {
        label: t('button.delete'),
        key: 'delete',
        onClick: () => {
          setDeleteDialogOpen(true);
        },
        icon: (
          <div className={'h-5 w-5'}>
            <TrashSvg />
          </div>
        ),
      },
      {
        key: 'duplicate',
        label: t('button.duplicate'),
        onClick: onDuplicate,
        icon: (
          <div className={'h-5 w-5'}>
            <CopySvg />
          </div>
        ),
      },
    ],
    [onDuplicate, t]
  );

  return (
    <>
      <ButtonPopoverList
        isVisible={isVisible}
        popoverOptions={options}
        popoverOrigin={{
          anchorOrigin: {
            vertical: 'bottom',
            horizontal: 'left',
          },
          transformOrigin: {
            vertical: 'top',
            horizontal: 'left',
          },
        }}
      >
        <IconButton size={'small'}>
          <DetailsSvg />
        </IconButton>
      </ButtonPopoverList>
      <RenameDialog
        defaultValue={page.name}
        open={renameDialogOpen}
        onClose={() => setRenameDialogOpen(false)}
        onOk={async (newName: string) => {
          await onRename(newName);
          setRenameDialogOpen(false);
        }}
      />
      <DeleteDialog
        layout={page.layout}
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
        onOk={async () => {
          await onDelete();
          setDeleteDialogOpen(false);
        }}
      />
    </>
  );
}

export default MoreButton;
