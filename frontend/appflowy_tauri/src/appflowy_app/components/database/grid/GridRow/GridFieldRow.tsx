import { VirtualItem } from '@tanstack/react-virtual';
import { t } from 'i18next';
import { FC } from 'react';
import { Button } from '@mui/material';
import { FieldType } from '@/services/backend';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import * as service from '$app/components/database/database_bd_svc';
import { useDatabase } from '../../database.hooks';
import { GridField } from '../GridField';

export const GridFieldRow: FC<{
  columnVirtualItems: VirtualItem[];
  before: number;
  after: number;
}> = ({ columnVirtualItems, before, after }) => {
  const { viewId, fields } = useDatabase();
  const handleClick = async () => {
    await service.createFieldTypeOption(viewId, FieldType.RichText);
  };

  return (
    <>
      <div
        className="flex border-t border-line-divider"
        style={{
          height: 41,
        }}
      >
        {before > 0 && <div style={{ width: before }} />}
        {columnVirtualItems.map(virtualColumn => (
          <div
            key={virtualColumn.key}
            className="border-r border-line-divider"
            data-index={virtualColumn.index}
            style={{
              width: `${virtualColumn.size}px`,
            }}
          >
            <GridField field={fields[virtualColumn.index]} />
          </div>
        ))}
        {after > 0 && <div style={{ width: after }} />}
      </div>
      <div className="w-44 grow flex items-center pl-2 border-t border-line-divider">
        <Button
          variant="text"
          color="inherit"
          size="small"
          startIcon={<AddSvg />}
          onClick={handleClick}
        >
          {t('grid.field.newColumn')}
        </Button>
      </div>
    </>
  );
}