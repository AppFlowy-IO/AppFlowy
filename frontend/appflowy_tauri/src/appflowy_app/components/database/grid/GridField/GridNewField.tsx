import React, { useCallback } from 'react';
import { useViewId } from '$app/hooks';
import { useTranslation } from 'react-i18next';
import { fieldService } from '$app/components/database/application';
import { FieldType } from '@/services/backend';
import Button from '@mui/material/Button';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';

function GridNewField({ onInserted }: { onInserted?: (id: string) => void }) {
  const viewId = useViewId();
  const { t } = useTranslation();

  const handleClick = useCallback(async () => {
    try {
      const field = await fieldService.createField({
        viewId,
        fieldType: FieldType.RichText,
      });

      onInserted?.(field.id);
    } catch (e) {
      // toast.error(t('grid.field.newPropertyFail'));
    }
  }, [onInserted, viewId]);

  return (
    <>
      <Button onClick={handleClick} className={'h-full w-full justify-start'} startIcon={<AddSvg />} color={'inherit'}>
        {t('grid.field.newProperty')}
      </Button>
    </>
  );
}

export default GridNewField;
