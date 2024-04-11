import React, { useCallback, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';

import { ReactComponent as DetailsSvg } from '$app/assets/details.svg';
import { ReactComponent as EditSvg } from '$app/assets/edit.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { ReactComponent as TrashSvg } from '$app/assets/delete.svg';

import RenameDialog from '../../_shared/confirm_dialog/RenameDialog';
import { Page } from '$app_reducers/pages/slice';
import DeleteDialog from '$app/components/layout/nested_page/DeleteDialog';
import OperationMenu from '$app/components/layout/nested_page/OperationMenu';
import { getModifier } from '$app/utils/hotkeys';
import isHotkey from 'is-hotkey';

function MoreButton({
  onDelete,
  onDuplicate,
  onRename,
  page,
  isHovering,
  setHovering,
}: {
  isHovering: boolean;
  setHovering: (hovering: boolean) => void;
  onDelete: () => Promise<void>;
  onDuplicate: () => Promise<void>;
  onRename: (newName: string) => Promise<void>;
  page: Page;
}) {
  const [renameDialogOpen, setRenameDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);

  const { t } = useTranslation();

  const onConfirm = useCallback(
    (key: string) => {
      switch (key) {
        case 'rename':
          setRenameDialogOpen(true);
          break;
        case 'delete':
          setDeleteDialogOpen(true);
          break;
        case 'duplicate':
          void onDuplicate();

          break;
        default:
          break;
      }
    },
    [onDuplicate]
  );

  const options = useMemo(
    () => [
      {
        title: t('button.rename'),
        icon: <EditSvg className={'h-4 w-4'} />,
        key: 'rename',
      },
      {
        key: 'delete',
        title: t('button.delete'),
        icon: <TrashSvg className={'h-4 w-4'} />,
        caption: 'Del',
      },
      {
        key: 'duplicate',
        title: t('button.duplicate'),
        icon: <CopySvg className={'h-4 w-4'} />,
        caption: `${getModifier()}+D`,
      },
    ],
    [t]
  );

  const onKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (isHotkey('del', e) || isHotkey('backspace', e)) {
        e.preventDefault();
        e.stopPropagation();
        onConfirm('delete');
        return;
      }

      if (isHotkey('mod+d', e)) {
        e.stopPropagation();
        onConfirm('duplicate');
        return;
      }
    },
    [onConfirm]
  );

  return (
    <>
      <OperationMenu
        tooltip={t('menuAppHeader.moreButtonToolTip')}
        isHovering={isHovering}
        setHovering={setHovering}
        onConfirm={onConfirm}
        options={options}
        onKeyDown={onKeyDown}
      >
        <DetailsSvg />
      </OperationMenu>

      <DeleteDialog
        layout={page.layout}
        open={deleteDialogOpen}
        onClose={() => {
          setDeleteDialogOpen(false);
        }}
        onOk={onDelete}
      />
      {renameDialogOpen && (
        <RenameDialog
          defaultValue={page.name}
          open={renameDialogOpen}
          onClose={() => setRenameDialogOpen(false)}
          onOk={onRename}
        />
      )}
    </>
  );
}

export default MoreButton;
