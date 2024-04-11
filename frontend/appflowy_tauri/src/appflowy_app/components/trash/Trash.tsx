import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import Button from '@mui/material/Button';
import { DeleteOutline, RestoreOutlined } from '@mui/icons-material';
import { useLoadTrash, useTrashActions } from '$app/components/trash/Trash.hooks';
import { List } from '@mui/material';
import TrashItem from '$app/components/trash/TrashItem';
import DeleteConfirmDialog from '$app/components/_shared/confirm_dialog/DeleteConfirmDialog';

function Trash() {
  const { t } = useTranslation();
  const { trash } = useLoadTrash();
  const {
    onPutback,
    onDelete,
    onClickRestoreAll,
    onClickDeleteAll,
    restoreAllDialogOpen,
    deleteAllDialogOpen,
    onRestoreAll,
    onDeleteAll,
    closeDialog,
    deleteDialogOpen,
    deleteId,
    onClickDelete,
  } = useTrashActions();
  const [hoverId, setHoverId] = useState('');

  return (
    <div className={'flex flex-col'}>
      <div className={'flex items-center justify-between'}>
        <div className={'px-2 text-lg font-bold'}>{t('trash.text')}</div>
        <div className={'flex items-center justify-end'}>
          <Button color={'inherit'} onClick={() => onClickRestoreAll()}>
            <RestoreOutlined />
            <span className={'ml-1'}>{t('trash.restoreAll')}</span>
          </Button>
          <Button color={'error'} onClick={() => onClickDeleteAll()}>
            <DeleteOutline />
            <span className={'ml-1'}>{t('trash.deleteAll')}</span>
          </Button>
        </div>
      </div>
      <div className={'flex justify-around gap-2 p-6 px-2 text-xs text-text-caption'}>
        <div className={'w-[40%]'}>{t('trash.pageHeader.fileName')}</div>
        <div className={'flex-1'}>{t('trash.pageHeader.lastModified')}</div>
        <div className={'flex-1'}>{t('trash.pageHeader.created')}</div>
        <div className={'w-[64px]'}></div>
      </div>
      <List>
        {trash.map((item) => (
          <TrashItem
            item={item}
            key={item.id}
            onPutback={onPutback}
            onDelete={onClickDelete}
            hoverId={hoverId}
            setHoverId={setHoverId}
          />
        ))}
      </List>
      <DeleteConfirmDialog
        open={restoreAllDialogOpen}
        title={t('trash.confirmRestoreAll.title')}
        subtitle={t('trash.confirmRestoreAll.caption')}
        onOk={onRestoreAll}
        onClose={closeDialog}
        okText={t('trash.restoreAll')}
      />
      <DeleteConfirmDialog
        open={deleteAllDialogOpen}
        title={t('trash.confirmDeleteAll.title')}
        subtitle={t('trash.confirmDeleteAll.caption')}
        onOk={onDeleteAll}
        onClose={closeDialog}
      />
      <DeleteConfirmDialog
        open={deleteDialogOpen}
        title={t('trash.confirmDeleteTitle')}
        onOk={() => onDelete([deleteId])}
        onClose={closeDialog}
      />
    </div>
  );
}

export default Trash;
