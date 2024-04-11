import { FC, FormEventHandler, Suspense, lazy, useCallback, useRef, useMemo } from 'react';
import { TextCell as TextCellType } from '$app/application/database';
import { CellText } from '../../_shared';
import { useInputCell } from '$app/components/database/components/cell/Cell.hooks';

const EditTextCellInput = lazy(() => import('$app/components/database/components/field_types/text/EditTextCellInput'));

interface TextCellProps {
  cell: TextCellType;
  placeholder?: string;
}
export const TextCell: FC<TextCellProps> = ({ placeholder, cell }) => {
  const cellRef = useRef<HTMLDivElement>(null);
  const { value, editing, updateCell, setEditing, setValue } = useInputCell(cell);
  const handleClose = () => {
    if (!cell) return;
    updateCell();
  };

  const handleClick = useCallback(() => {
    if (!cell) return;
    setValue(cell.data);
    setEditing(true);
  }, [cell, setEditing, setValue]);

  const handleInput = useCallback<FormEventHandler<HTMLTextAreaElement>>(
    (event) => {
      setValue((event.target as HTMLTextAreaElement).value);
    },
    [setValue]
  );

  const content = useMemo(() => {
    if (cell && typeof cell.data === 'string' && cell.data) {
      return cell.data;
    }

    return <div className={'text-text-placeholder'}>{placeholder}</div>;
  }, [cell, placeholder]);

  return (
    <>
      <CellText className={`min-h-[36px] w-full cursor-text`} ref={cellRef} onClick={handleClick}>
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
};
