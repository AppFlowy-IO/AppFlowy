import React, { useMemo, useState } from 'react';
import { EditSvg } from '$app/components/_shared/svg/EditSvg';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import { CopySvg } from '$app/components/_shared/svg/CopySvg';
import MenuItem from '@mui/material/MenuItem';
import { useTranslation } from 'react-i18next';
import RenameDialog from '$app/components/layout/NavigationPanel/RenameDialog';
import { IPage } from '$app_reducers/pages/slice';

function MoreMenu({
  selectedPage,
  onRename,
  onDeleteClick,
  onDuplicateClick,
}: {
  selectedPage: IPage;
  onRename: (name: string) => Promise<void>;
  onDeleteClick: () => void;
  onDuplicateClick: () => void;
}) {
  const { t } = useTranslation();
  const [renameDialogOpen, setRenameDialogOpen] = useState(false);

  const items = useMemo(
    () => [
      {
        icon: (
          <i className={'h-[16px] w-[16px] text-text-title'}>
            <EditSvg></EditSvg>
          </i>
        ),
        onClick: () => {
          setRenameDialogOpen(true);
        },
        title: t('disclosureAction.rename'),
      },
      {
        icon: (
          <i className={'h-[16px] w-[16px] text-text-title'}>
            <TrashSvg></TrashSvg>
          </i>
        ),
        onClick: onDeleteClick,
        title: t('disclosureAction.delete'),
      },
      {
        icon: (
          <i className={'h-[16px] w-[16px] text-text-title'}>
            <CopySvg></CopySvg>
          </i>
        ),
        onClick: onDuplicateClick,
        title: t('disclosureAction.duplicate'),
      },
    ],
    [onDeleteClick, onDuplicateClick, t]
  );

  return (
    <>
      {items.map((item, index) => {
        return (
          <MenuItem key={index} onClick={item.onClick}>
            <div className={'flex items-center gap-2'}>
              {item.icon}
              <span className={'flex-shrink-0'}>{item.title}</span>
            </div>
          </MenuItem>
        );
      })}
      <RenameDialog
        defaultValue={selectedPage.title}
        open={renameDialogOpen}
        onClose={() => setRenameDialogOpen(false)}
        onOk={async (val: string) => {
          await onRename(val);
          setRenameDialogOpen(false);
        }}
      />
    </>
  );
}

export default MoreMenu;
