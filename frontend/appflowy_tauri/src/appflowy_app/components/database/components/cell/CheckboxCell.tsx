import { Checkbox } from '@mui/material';
import { FC, useCallback } from 'react';
import { ReactComponent as CheckboxCheckSvg } from '$app/assets/database/checkbox-check.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$app/assets/database/checkbox-uncheck.svg';
import { useViewId } from '$app/hooks';
import { cellService, CheckboxCell as CheckboxCellType, Field } from '../../application';

export const CheckboxCell: FC<{
  field: Field,
  cell: CheckboxCellType,
}> = ({ field, cell }) => {
  const viewId = useViewId();
  const checked = cell.data === 'Yes';

  const handleClick = useCallback(() => {
    void cellService.updateCell(
      viewId,
      cell.rowId,
      field.id,
      !checked ? 'Yes' : 'No',
    );
  }, [viewId, cell.rowId, field.id, checked ]);

  return (
    <div className="flex items-center w-full px-2 cursor-pointer" onClick={handleClick}>
      <Checkbox
        disableRipple
        style={{ padding: 0 }}
        checked={checked}
        icon={<CheckboxUncheckSvg />}
        checkedIcon={<CheckboxCheckSvg />}
      />
    </div>
  );
};
