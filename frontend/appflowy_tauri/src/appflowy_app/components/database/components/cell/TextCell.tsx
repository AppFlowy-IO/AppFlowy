import { Popover, TextareaAutosize } from '@mui/material';
import { FC, FormEventHandler, useCallback, useLayoutEffect, useRef, useState } from 'react';
import { useViewId } from '$app/hooks';
import { cellService, Field, TextCell as TextCellType } from '../../application';
import { CellText } from '../../_shared';

export const TextCell: FC<{
  field: Field,
  cell: TextCellType;
}> = ({ field, cell }) => {
  const viewId = useViewId();
  const cellRef = useRef<HTMLDivElement>(null);
  const [ editing, setEditing ] = useState(false);
  const [ text, setText ] = useState('');
  const [ width, setWidth ] = useState<number | undefined>(undefined);

  const handleClose = () => {
    if (editing) {
      if (text !== cell.data) {
        void cellService.updateCell(viewId, cell.rowId, field.id, text);
      }

      setEditing(false);
    }
  };

  const handleClick = useCallback(() => {
    setText(cell.data);
    setEditing(true);
  }, [cell.data]);

  const handleInput = useCallback<FormEventHandler<HTMLTextAreaElement>>((event) => {
    setText((event.target as HTMLTextAreaElement).value);
  }, []);

  useLayoutEffect(() => {
    if (cellRef.current) {
      setWidth(cellRef.current.clientWidth);
    }
  }, [editing]);

  return (
    <>
      <CellText
        ref={cellRef}
        className="w-full"
        onClick={handleClick}
      >
        {cell.data}
      </CellText>
      {editing && (
        <Popover
          open={editing}
          anchorEl={cellRef.current}
          PaperProps={{
            className: 'flex p-2 border border-blue-400',
            style: { width, borderRadius: 0, boxShadow: 'none' },
          }}
          transformOrigin={{
            vertical: 1,
            horizontal: 'left',
          }}
          transitionDuration={0}
          onClose={handleClose}
        >
          <TextareaAutosize
            className="resize-none text-sm"
            autoFocus
            autoCorrect="off"
            value={text}
            onInput={handleInput}
          />
        </Popover>
      )}
    </>
  );
};
