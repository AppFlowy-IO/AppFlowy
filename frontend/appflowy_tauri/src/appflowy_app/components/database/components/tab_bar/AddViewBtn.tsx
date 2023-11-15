import React from 'react';
import { IconButton } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useTranslation } from 'react-i18next';
import { ViewLayoutPB } from '@/services/backend';
import { createDatabaseView } from '$app/components/database/application/database_view/database_view_service';

function AddViewBtn({ pageId }: { pageId: string }) {
  const { t } = useTranslation();
  const onClick = async () => {
    try {
      await createDatabaseView(pageId, ViewLayoutPB.Grid, t('editor.table'));
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
