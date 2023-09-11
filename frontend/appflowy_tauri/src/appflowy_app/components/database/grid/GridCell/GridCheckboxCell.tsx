import { Database } from '$app/interfaces/database';
import { Checkbox } from '@mui/material';
import { FC, useCallback } from 'react';
import { ReactComponent as CheckboxCheckSvg } from '$app/assets/database/checkbox-check.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$app/assets/database/checkbox-uncheck.svg';
import * as service from '$app/components/database/database_bd_svc';
import { useViewId } from '../../database.hooks';

export const GridCheckboxCell: FC<{
  rowId: string;
  cell: Database.CheckboxCell | null,
  field: Database.Field,
}> = ({ rowId, field, cell }) => {
  const viewId = useViewId();
  const handleChange = useCallback((event: React.ChangeEvent<HTMLInputElement>, checked: boolean) => {
    void service.updateCell(viewId, rowId, field.id, checked ? 'Yes' : 'No');
  }, [viewId, rowId, field.id ]);

  return (
    <div className="flex h-full items-center px-3">
      <Checkbox
        disableRipple
        style={{ padding: 0 }}
        checked={cell?.data === 'Yes'}
        icon={<CheckboxUncheckSvg />}
        checkedIcon={<CheckboxCheckSvg />}
        onChange={handleChange}
      />
    </div>
  );
};
