import React, { FormEventHandler, lazy, Suspense, useCallback, useRef } from 'react';
import { useInputCell } from '$app/components/database/components/cell/Cell.hooks';
import { Field, UrlCell as URLCellType } from '$app/components/database/application';
import { CellText } from '$app/components/database/_shared';

const EditTextCellInput = lazy(() => import('$app/components/database/components/field_types/text/EditTextCellInput'));

interface Props {
  field: Field;
  cell?: URLCellType;
}
function UrlCell({ field, cell }: Props) {
  const cellRef = useRef<HTMLDivElement>(null);
  const { value, editing, updateCell, setEditing, setValue } = useInputCell(cell);
  const handleClick = useCallback(() => {
    if (!cell) return;
    setValue(cell.data.content || '');
    setEditing(true);
  }, [cell, setEditing, setValue]);

  const handleClose = () => {
    if (!cell) return;
    updateCell();
  };

  const handleInput = useCallback<FormEventHandler<HTMLTextAreaElement>>(
    (event) => {
      setValue((event.target as HTMLTextAreaElement).value);
    },
    [setValue]
  );

  return (
    <>
      <CellText
        style={{
          width: `${field.width}px`,
          minHeight: 37,
        }}
        ref={cellRef}
        onClick={handleClick}
      >
        <div className={`flex w-full items-center whitespace-break-spaces break-all text-content-blue-400 underline`}>
          {cell?.data.content}
        </div>
      </CellText>
      <Suspense>
        {editing && (
          <EditTextCellInput
            editing={editing}
            anchorEl={cellRef.current}
            width={field.width}
            onClose={handleClose}
            text={value}
            onInput={handleInput}
          />
        )}
      </Suspense>
    </>
  );
}

export default UrlCell;
