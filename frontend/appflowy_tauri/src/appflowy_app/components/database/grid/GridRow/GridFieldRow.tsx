import { Virtualizer } from '@tanstack/react-virtual';
import { FC } from 'react';
import { Button } from '@mui/material';
import { FieldType } from '@/services/backend';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import * as service from '$app/components/database/database_bd_svc';
import { useDatabase } from '../../database.hooks';
import { VirtualizedList } from '../../_shared';
import { GridField } from '../GridField';

export interface GridFieldRowProps {
  virtualizer: Virtualizer<Element, Element>;
}

export const GridFieldRow: FC<GridFieldRowProps> = ({
  virtualizer,
}) => {
  const { viewId, fields } = useDatabase();
  const handleClick = async () => {
    await service.createFieldTypeOption(viewId, FieldType.RichText);
  };

  return (
    <div className="flex grow border-b border-line-divider">
      <VirtualizedList
        className="flex"
        virtualizer={virtualizer}
        itemClassName="flex border-r border-line-divider"
        renderItem={index => <GridField field={fields[index]} />}
      />
      <div className="min-w-20 grow">
        <Button
          className="w-full h-full"
          size="small"
          startIcon={<AddSvg />}
          onClick={handleClick}
        />
      </div>
    </div>
  );
};
