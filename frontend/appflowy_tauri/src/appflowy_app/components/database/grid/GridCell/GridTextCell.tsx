import { Popover, TextareaAutosize } from '@mui/material';
import { FC, FormEventHandler, useCallback, useEffect, useRef, useState } from 'react';
import { Database } from '$app/interfaces/database';
import * as service from '$app/components/database/database_bd_svc';
import { useViewId } from '../../database.hooks';
import { CellText } from '../../_shared';

export const GridTextCell: FC<{
  rowId: string;
  field: Database.Field,
  cell: Database.TextCell | null;
}> = ({ rowId, field, cell }) => {
  const viewId = useViewId();
  const [ editing, setEditing ] = useState(false);
  const [ text, setText ] = useState('');
  const [ width, setWidth ] = useState<number | undefined>(undefined);
  const cellRef = useRef<HTMLDivElement>(null);

  const handleClose = () => {
    if (editing) {
      if (text !== cell?.data) {
        void service.updateCell(viewId, rowId, field.id, text);
      }

      setEditing(false);
    }
  };

  const handleDoubleClick = useCallback(() => {
    setText(cell?.data ?? '');
    setEditing(true);
  }, [cell?.data]);

  const handleInput = useCallback<FormEventHandler<HTMLTextAreaElement>>((event) => {
    setText((event.target as HTMLTextAreaElement).value);
  }, []);

  useEffect(() => {
    if (cellRef.current) {
      setWidth(cellRef.current.clientWidth);
    }
  }, [editing]);

  return (
    <>
      <CellText
        ref={cellRef}
        className="w-full"
        onDoubleClick={handleDoubleClick}
      >
        {cell?.data}
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
