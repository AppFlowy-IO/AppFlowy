import React, { MouseEvent, useCallback, useState } from 'react';
import { Field, fieldService } from '$app/components/database/application';
import { FieldType } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import Button from '@mui/material/Button';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useViewId } from '$app/hooks';
import { FieldMenu } from '$app/components/database/components/field/FieldMenu';

function NewProperty() {
  const viewId = useViewId();
  const { t } = useTranslation();
  const [anchorEl, setAnchorEl] = useState<HTMLButtonElement | null>(null);
  const open = Boolean(anchorEl);
  const [updateField, setUpdateField] = useState<Field | null>(null);

  const handleClick = useCallback(
    async (e: MouseEvent<HTMLButtonElement>) => {
      try {
        const field = await fieldService.createField(viewId, FieldType.RichText);

        setUpdateField(field);
        setAnchorEl(e.target as HTMLButtonElement);
      } catch (e) {
        // toast.error(t('grid.field.newPropertyFail'));
      }
    },
    [viewId]
  );

  return (
    <>
      <Button onClick={handleClick} className={'h-full w-full justify-start'} startIcon={<AddSvg />} color={'inherit'}>
        {t('grid.field.newProperty')}
      </Button>
      {updateField && (
        <FieldMenu
          field={updateField}
          anchorEl={anchorEl}
          open={open}
          onClose={() => {
            setUpdateField(null);
            setAnchorEl(null);
          }}
        />
      )}
    </>
  );
}

export default NewProperty;
