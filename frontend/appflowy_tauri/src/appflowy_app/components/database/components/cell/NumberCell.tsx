import React, { Suspense, useCallback, useMemo, useRef } from 'react';
import { Field, NumberCell as NumberCellType } from '$app/application/database';
import { CellText } from '$app/components/database/_shared';
import EditNumberCellInput from '$app/components/database/components/field_types/number/EditNumberCellInput';
import { useInputCell } from '$app/components/database/components/cell/Cell.hooks';

interface Props {
  field: Field;
  cell: NumberCellType;
  placeholder?: string;
}

function NumberCell({ field, cell, placeholder }: Props) {
  const cellRef = useRef<HTMLDivElement>(null);
  const { value, editing, updateCell, setEditing, setValue } = useInputCell(cell);
  const content = useMemo(() => {
    if (typeof cell.data === 'string' && cell.data) {
      return cell.data;
    }

    return <div className={'text-sm text-text-placeholder'}>{placeholder}</div>;
  }, [cell, placeholder]);

  const handleClick = useCallback(() => {
    setValue(cell.data);
    setEditing(true);
  }, [cell, setEditing, setValue]);

  return (
    <>
      <CellText className={'min-h-[36px]'} ref={cellRef} onClick={handleClick}>
        <div className='flex w-full items-center'>{content}</div>
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
