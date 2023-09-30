import { useCallback } from 'react';
import { t } from 'i18next';
import { Button } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import * as service from '$app/components/database/database_bd_svc';
import { useDatabase, useViewId } from '../../database.hooks';

export const GridNewRow = () => {
  const viewId = useViewId();
  const { rows } = useDatabase();
  const lastRowId = rows.at(-1)?.id;

  const handleClick = useCallback(() => {
    void service.createRow(viewId, {
      startRowId: lastRowId,
    });
  }, [viewId, lastRowId]);

  return (
    <div className="flex grow border-b border-line-divider">
      <Button
        className="grow justify-start"
        onClick={handleClick}
      >
        <span className="inline-flex items-center sticky left-[72px]">
          <AddSvg className="text-base mr-1" />
          {t('grid.row.newRow')}
        </span>
      </Button>
    </div>
  );
};
