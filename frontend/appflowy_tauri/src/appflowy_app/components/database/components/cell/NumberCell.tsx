import React, { Suspense, useCallback, useMemo, useRef } from 'react';
import { Field, NumberCell as NumberCellType } from '$app/components/database/application';
import { CellText } from '$app/components/database/_shared';
import EditNumberCellInput from '$app/components/database/components/field_types/number/EditNumberCellInput';
import { useInputCell } from '$app/components/database/components/cell/Cell.hooks';

interface Props {
  field: Field;
  cell?: NumberCellType;
}

function NumberCell({ field, cell }: Props) {
  const cellRef = useRef<HTMLDivElement>(null);
  const { value, editing, updateCell, setEditing, setValue } = useInputCell(cell);
  const content = useMemo(() => {
    if (cell && typeof cell.data === 'string') {
      return cell.data;
    }

    return null;
  }, [cell]);

  const handleClick = useCallback(() => {
    if (!cell) return;
    setValue(cell.data);
    setEditing(true);
  }, [cell, setEditing, setValue]);

  return (
    <>
      <CellText ref={cellRef} onClick={handleClick}>
        <div className='flex h-full w-full items-center justify-end'>{content}</div>
      </CellText>
      <Suspense>
        {editing && (
          <EditNumberCellInput
            editing={editing}
            anchorEl={cellRef.current}
            width={field?.width}
            onClose={updateCell}
            value={value}
            onChange={setValue}
          />
        )}
      </Suspense>
    </>
  );
}

export default NumberCell;
