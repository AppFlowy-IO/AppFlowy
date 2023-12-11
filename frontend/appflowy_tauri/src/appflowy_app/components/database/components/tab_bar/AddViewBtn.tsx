import React from 'react';
import { IconButton } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useTranslation } from 'react-i18next';
import { ViewLayoutPB } from '@/services/backend';
import { createDatabaseView } from '$app/components/database/application/database_view/database_view_service';

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
    <IconButton onClick={onClick} size='small'>
      <AddSvg />
    </IconButton>
  );
}

export default AddViewBtn;
