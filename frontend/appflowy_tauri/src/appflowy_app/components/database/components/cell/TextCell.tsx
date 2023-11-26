import { FC, FormEventHandler, Suspense, lazy, useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';
import { useViewId } from '$app/hooks';
import { cellService, Field, TextCell as TextCellType } from '../../application';
import { CellText } from '../../_shared';
import { useGridUIStateDispatcher, useGridUIStateSelector } from '$app/components/database/proxy/grid/ui_state/actions';

const ExpandButton = lazy(() => import('$app/components/database/components/cell/ExpandButton'));
const EditTextCellInput = lazy(() => import('$app/components/database/components/cell/EditTextCellInput'));

export const TextCell: FC<{
  field: Field;
  cell?: TextCellType;
  documentId?: string;
  icon?: string;
  placeholder?: string;
}> = ({ field, cell, documentId, icon, placeholder }) => {
  const isPrimary = field.isPrimary;
  const viewId = useViewId();
  const cellRef = useRef<HTMLDivElement>(null);
  const [editing, setEditing] = useState(false);
  const [text, setText] = useState('');
  const [width, setWidth] = useState<number | undefined>(undefined);
  const { hoverRowId } = useGridUIStateSelector();
  const isHover = hoverRowId === cell?.rowId;
  const { setRowHover } = useGridUIStateDispatcher();
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const showExpandIcon = cell && !editing && isHover && isPrimary;
  const handleClose = () => {
    if (!cell) return;
    if (editing) {
      if (text !== cell.data) {
        void cellService.updateCell(viewId, cell.rowId, field.id, text);
      }

      setEditing(false);
    }
  };

  const handleClick = useCallback(() => {
    if (!cell) return;
    setText(cell.data);
    setEditing(true);
  }, [cell]);

  const handleInput = useCallback<FormEventHandler<HTMLTextAreaElement>>((event) => {
    setText((event.target as HTMLTextAreaElement).value);
  }, []);

  useLayoutEffect(() => {
    if (cellRef.current) {
      setWidth(cellRef.current.clientWidth);
    }
  }, [editing]);

  useEffect(() => {
    if (editing) {
      setRowHover(null);
    }
  }, [editing, setRowHover]);

  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.focus();
      // set the cursor to the end of the text
      textareaRef.current.setSelectionRange(textareaRef.current.value.length, textareaRef.current.value.length);
    }
  }, []);

  return (
    <>
      <CellText ref={cellRef} onClick={handleClick}>
        <div className='flex w-full items-center'>
          {icon && <div className={'mr-2'}>{icon}</div>}
          {cell?.data || <div className={'text-text-placeholder'}>{placeholder}</div>}
        </div>
      </CellText>
      <Suspense>
        {cell && <ExpandButton visible={showExpandIcon} icon={icon} documentId={documentId} cell={cell} />}
        {editing && (
          <EditTextCellInput
            editing={editing}
            anchorEl={cellRef.current}
            width={width}
            onClose={handleClose}
            text={text}
            onInput={handleInput}
          />
        )}
      </Suspense>
    </>
  );
};
