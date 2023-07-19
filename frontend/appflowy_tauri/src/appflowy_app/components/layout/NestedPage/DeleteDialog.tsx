import React from 'react';
import { useTranslation } from 'react-i18next';
import { ViewLayoutPB } from '@/services/backend';
import ConfirmDialog from '$app/components/_shared/app-dialog/ConfirmDialog';

function DeleteDialog({
  layout,
  open,
  onClose,
  onOk,
}: {
  layout: ViewLayoutPB;
  open: boolean;
  onClose: () => void;
  onOk: () => Promise<void>;
}) {
  const { t } = useTranslation();

  const pageType = {
    [ViewLayoutPB.Document]: t('document.menuName'),
    [ViewLayoutPB.Grid]: t('grid.menuName'),
    [ViewLayoutPB.Board]: t('board.menuName'),
    [ViewLayoutPB.Calendar]: t('calendar.menuName'),
  }[layout];

  return (
    <ConfirmDialog
      open={open}
      title={t('views.deleteContentTitle', {
        pageType,
      })}
      subtitle={t('views.deleteContentCaption', {
        pageType,
      })}
      onOk={onOk}
      onClose={onClose}
    />
  );
}

export default DeleteDialog;
