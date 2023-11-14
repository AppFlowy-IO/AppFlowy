import { Button } from '@mui/material';
import { FieldType } from '@/services/backend';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { fieldService } from '../../application';
import { useDatabaseVisibilityFields } from '../../Database.hooks';
import { GridField } from '../GridField';
import { useViewId } from '@/appflowy_app/hooks';
import { useTranslation } from 'react-i18next';
import { DEFAULT_FIELD_WIDTH } from '$app/components/database/grid/GridRow/constants';

export const GridFieldRow = () => {
  const { t } = useTranslation();
  const viewId = useViewId();
  const fields = useDatabaseVisibilityFields();

  const handleClick = async () => {
    await fieldService.createField(viewId, FieldType.RichText);
  };

  return (
    <div className='z-10 flex border-b border-line-divider'>
      <div className={'flex'}>
        {fields.map((field) => {
          return <GridField key={field.id} field={field} />;
        })}
      </div>

      <div className={`w-[${DEFAULT_FIELD_WIDTH}px]`}>
        <Button
          color={'inherit'}
          className='flex h-full w-full items-center justify-start whitespace-nowrap text-left'
          size='small'
          startIcon={<AddSvg />}
          onClick={handleClick}
        >
          {t('grid.field.newColumn')}
        </Button>
      </div>
    </div>
  );
};
