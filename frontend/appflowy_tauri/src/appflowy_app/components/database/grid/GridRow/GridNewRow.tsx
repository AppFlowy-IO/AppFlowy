import { useCallback } from 'react';
import { t } from 'i18next';
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
    <div
      className="flex flex-1 h-9 items-center px-1 py-2 cursor-pointer"
      onClick={handleClick}
    >
      <AddSvg className="text-base mr-1" />
      <span className="text-xs font-medium">
        {t('grid.row.newRow')}
      </span>
    </div>
  );
};