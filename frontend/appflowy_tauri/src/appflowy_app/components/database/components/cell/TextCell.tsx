import { FC, FormEventHandler, Suspense, lazy, useCallback, useEffect, useRef, useMemo } from 'react';
import { Field, TextCell as TextCellType } from '../../application';
import { CellText } from '../../_shared';
import { useGridUIStateDispatcher, useGridUIStateSelector } from '$app/components/database/proxy/grid/ui_state/actions';
import { useInputCell } from '$app/components/database/components/cell/Cell.hooks';

const ExpandButton = lazy(() => import('$app/components/database/components/cell/ExpandButton'));
const EditTextCellInput = lazy(() => import('$app/components/database/components/field_types/text/EditTextCellInput'));

export const TextCell: FC<{
  field: Field;
  cell: TextCellType;
  documentId?: string;
  icon?: string;
  placeholder?: string;
}> = ({ field, documentId, icon, placeholder, cell }) => {
  const isPrimary = field.isPrimary;
  const cellRef = useRef<HTMLDivElement>(null);
  const { value, editing, updateCell, setEditing, setValue } = useInputCell(cell);

  const { hoverRowId } = useGridUIStateSelector();
  const isHover = hoverRowId === cell?.rowId;
  const { setRowHover } = useGridUIStateDispatcher();

  const showExpandIcon = cell && !editing && isHover && isPrimary;
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

  useEffect(() => {
    if (editing) {
      setRowHover(null);
    }
  }, [editing, setRowHover]);

  const content = useMemo(() => {
    if (cell && typeof cell.data === 'string' && cell.data) {
      return cell.data;
    }

    return <div className={'text-text-placeholder'}>{placeholder}</div>;
  }, [cell, placeholder]);

  return (
    <div className={'relative h-full'}>
      <CellText
        style={{
          width: `${field.width}px`,
          minHeight: 37,
        }}
        ref={cellRef}
        onClick={handleClick}
      >
        <div className={`flex h-full w-full items-center whitespace-break-spaces break-all`}>
          {icon && <div className={'mr-2'}>{icon}</div>}
          {content}
        </div>
      </CellText>
      <Suspense>
        {cell && <ExpandButton visible={showExpandIcon} icon={icon} documentId={documentId} cell={cell} />}
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
    </div>
  );
};
