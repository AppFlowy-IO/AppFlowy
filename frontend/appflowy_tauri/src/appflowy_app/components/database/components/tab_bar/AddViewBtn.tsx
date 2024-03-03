import React from 'react';
import { IconButton } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useTranslation } from 'react-i18next';
import { ViewLayoutPB } from '@/services/backend';
import { createDatabaseView } from '$app/application/database/database_view/database_view_service';

function AddViewBtn({ pageId, onCreated }: { pageId: string; onCreated: (id: string) => void }) {
  const { t } = useTranslation();
  const onClick = async () => {
    try {
      const view = await createDatabaseView(pageId, ViewLayoutPB.Grid, t('editor.table'));

      onCreated(view.id);
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className={'ml-1 flex items-center justify-center border-l border-line-divider px-1'}>
      <IconButton className={'flex items-center justify-center'} onClick={onClick} size='small'>
        <AddSvg />
      </IconButton>
    </div>
  );
}

export default AddViewBtn;
