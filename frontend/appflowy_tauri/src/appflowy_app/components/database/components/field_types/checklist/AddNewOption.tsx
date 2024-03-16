import React, { useState } from 'react';
import { updateChecklistCell } from '$app/application/database/cell/cell_service';
import { useViewId } from '$app/hooks';
import { Button } from '@mui/material';
import { useTranslation } from 'react-i18next';

function AddNewOption({
  rowId,
  fieldId,
  onClose,
  onFocus,
}: {
  rowId: string;
  fieldId: string;
  onClose: () => void;
  onFocus: () => void;
}) {
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
    <div className={'flex items-center justify-between p-2 px-2 text-sm'}>
      <input
        onFocus={onFocus}
        placeholder={t('grid.checklist.addNew')}
        className={'flex-1 px-2'}
        autoFocus={true}
        onKeyDown={(e) => {
          if (e.key === 'Enter') {
            e.stopPropagation();
            e.preventDefault();
            void createOption();
            return;
          }

          if (e.key === 'Escape') {
            e.stopPropagation();
            e.preventDefault();
            onClose();
            return;
          }
        }}
        value={value}
        spellCheck={false}
        onChange={(e) => {
          setValue(e.target.value);
        }}
      />
      <Button variant={'contained'} className={'text-xs'} size={'small'} disabled={!value} onClick={createOption}>
        {t('grid.selectOption.create')}
      </Button>
    </div>
  );
}

export default AddNewOption;
