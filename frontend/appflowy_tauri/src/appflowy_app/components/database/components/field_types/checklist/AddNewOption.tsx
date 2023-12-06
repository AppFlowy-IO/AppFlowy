import React, { useState } from 'react';
import { updateChecklistCell } from '$app/components/database/application/cell/cell_service';
import { useViewId } from '$app/hooks';
import { ReactComponent as AddIcon } from '$app/assets/add.svg';
import { IconButton } from '@mui/material';
import { useTranslation } from 'react-i18next';

function AddNewOption({ rowId, fieldId }: { rowId: string; fieldId: string }) {
  const { t } = useTranslation();
  const [value, setValue] = useState('');
  const viewId = useViewId();
  const createOption = async () => {
    await updateChecklistCell(viewId, rowId, fieldId, {
      insertOptions: [value],
    });
    setValue('');
  };

  return (
    <div className={'flex items-center justify-between p-2 px-4 text-sm'}>
      <input
        placeholder={t('grid.checklist.addNew')}
        className={'flex-1'}
        onKeyDown={(e) => {
          if (e.key === 'Enter') {
            void createOption();
          }
        }}
        value={value}
        onChange={(e) => {
          setValue(e.target.value);
        }}
      />
      <IconButton size={'small'} disabled={!value} onClick={createOption}>
        <AddIcon />
      </IconButton>
    </div>
  );
}

export default AddNewOption;
