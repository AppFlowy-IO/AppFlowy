import React, { FormEventHandler, lazy, Suspense, useCallback, useMemo, useRef } from 'react';
import { useInputCell } from '$app/components/database/components/cell/Cell.hooks';
import { Field, UrlCell as URLCellType } from '$app/application/database';
import { CellText } from '$app/components/database/_shared';
import { openUrl } from '$app/utils/open_url';

const EditTextCellInput = lazy(() => import('$app/components/database/components/field_types/text/EditTextCellInput'));

interface Props {
  field: Field;
  cell: URLCellType;
  placeholder?: string;
}

function UrlCell({ field, cell, placeholder }: Props) {
  const cellRef = useRef<HTMLDivElement>(null);
  const { value, editing, updateCell, setEditing, setValue } = useInputCell(cell);
  const handleClick = useCallback(() => {
    setValue(cell.data.content || '');
    setEditing(true);
  }, [cell, setEditing, setValue]);

  const handleClose = () => {
    updateCell();
  };

  const handleInput = useCallback<FormEventHandler<HTMLTextAreaElement>>(
    (event) => {
      setValue((event.target as HTMLTextAreaElement).value);
    },
    [setValue]
  );

  const content = useMemo(() => {
    const str = cell.data.content;

    if (str) {
      return (
        <a
          onClick={(e) => {
            e.stopPropagation();
            openUrl(str);
          }}
          target={'_blank'}
          className={'cursor-pointer text-content-blue-400 underline'}
        >
          {str}
        </a>
      );
    }

    return <div className={'cursor-text text-sm text-text-placeholder'}>{placeholder}</div>;
  }, [cell, placeholder]);

  return (
    <>
      <CellText
        style={{
          width: `${field.width}px`,
          minHeight: 37,
        }}
        className={'cursor-text'}
        ref={cellRef}
        onClick={handleClick}
      >
        {content}
      </CellText>
      <Suspense>
        {editing && (
          <EditTextCellInput
            editing={editing}
            anchorEl={cellRef.current}
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
