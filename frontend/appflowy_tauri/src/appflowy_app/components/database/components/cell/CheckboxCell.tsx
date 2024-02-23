import React, { FC, useCallback } from 'react';
import { ReactComponent as CheckboxCheckSvg } from '$app/assets/database/checkbox-check.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$app/assets/database/checkbox-uncheck.svg';
import { useViewId } from '$app/hooks';
import { cellService, CheckboxCell as CheckboxCellType, Field } from '$app/application/database';

export const CheckboxCell: FC<{
  field: Field;
  cell: CheckboxCellType;
}> = ({ field, cell }) => {
  const viewId = useViewId();
  const checked = cell.data;

  const handleClick = useCallback(() => {
    void cellService.updateCell(viewId, cell.rowId, field.id, !checked ? 'Yes' : 'No');
  }, [viewId, cell, field.id, checked]);

  return (
    <div
      className='relative flex w-full cursor-pointer items-center px-2 text-lg text-fill-default'
      onClick={handleClick}
    >
      {checked ? <CheckboxCheckSvg /> : <CheckboxUncheckSvg />}
    </div>
  );
};
