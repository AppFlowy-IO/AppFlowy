import React, { FormEventHandler, lazy, Suspense, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useInputCell } from '$app/components/database/components/cell/Cell.hooks';
import { Field, UrlCell as URLCellType } from '$app/components/database/application';
import { CellText } from '$app/components/database/_shared';

const EditTextCellInput = lazy(() => import('$app/components/database/components/field_types/text/EditTextCellInput'));

const pattern = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([/\w.-]*)*\/?$/;

interface Props {
  field: Field;
  cell: URLCellType;
  placeholder?: string;
}

function UrlCell({ field, cell, placeholder }: Props) {
  const [isUrl, setIsUrl] = useState(false);
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

  useEffect(() => {
    if (editing) return;
    const str = cell.data.content;

    if (!str) return;
    const isUrl = pattern.test(str);

    setIsUrl(isUrl);
  }, [cell, editing]);

  const content = useMemo(() => {
    const str = cell.data.content;

    if (str) {
      if (isUrl) {
        return (
          <a href={str} target={'_blank'} className={'cursor-pointer text-content-blue-400 underline'}>
            {str}
          </a>
        );
      }

      return str;
    }

    return <div className={'text-sm text-text-placeholder'}>{placeholder}</div>;
  }, [isUrl, cell, placeholder]);

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
