import { Virtualizer } from '@tanstack/react-virtual';
import { FC } from 'react';
import { Button } from '@mui/material';
import { FieldType } from '@/services/backend';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { fieldService } from '../../application';
import { useDatabase } from '../../Database.hooks';
import { VirtualizedList } from '../../_shared';
import { GridField } from '../GridField';
import { useViewId } from '@/appflowy_app/hooks';
import { useTranslation } from 'react-i18next';

export interface GridFieldRowProps {
  virtualizer: Virtualizer<Element, Element>;
}

export const GridFieldRow: FC<GridFieldRowProps> = ({ virtualizer }) => {
  const { t } = useTranslation();
  const viewId = useViewId();
  const { fields } = useDatabase();
  const handleClick = async () => {
    await fieldService.createField(viewId, FieldType.RichText);
  };

  return (
    <div className='flex grow border-b border-line-divider'>
      <VirtualizedList
        className='flex'
        virtualizer={virtualizer}
        itemClassName='flex border-r border-line-divider'
        renderItem={(index) => <GridField field={fields[index]} />}
      />
      <div className='min-w-20 grow'>
        <Button color={'inherit'} className='h-full w-full' size='small' startIcon={<AddSvg />} onClick={handleClick}>
          {t('grid.field.newColumn')}
        </Button>
      </div>
    </div>
  );
};
