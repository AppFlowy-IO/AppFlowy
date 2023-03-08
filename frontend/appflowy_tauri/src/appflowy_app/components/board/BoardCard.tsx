import { DatabaseFieldMap, IDatabaseColumn, IDatabaseRow } from '../../stores/reducers/database/slice';
import { Details2Svg } from '../_shared/svg/Details2Svg';
import { FieldType } from '../../../services/backend';
import { getBgColor } from '../_shared/getColor';
import { MouseEventHandler, useEffect, useRef, useState } from 'react';
import { RowInfo } from '../../stores/effects/database/row/row_cache';
import { useRow } from '../_shared/database-hooks/useRow';
import { DatabaseController } from '../../stores/effects/database/database_controller';
import { useAppSelector } from '../../stores/store';
import { BoardCell } from './BoardCell';

export const BoardCard = ({
  viewId,
  controller,
  groupingFieldId,
  // fields,
  // columns,
  row,
  startMove,
  endMove,
}: {
  viewId: string;
  controller: DatabaseController;
  groupingFieldId: string;
  // fields: DatabaseFieldMap;
  // columns: IDatabaseColumn[];
  row: RowInfo;
  startMove: () => void;
  endMove: () => void;
}) => {
  const { cells } = useRow(viewId, controller, row);

  const databaseStore = useAppSelector((state) => state.database);
  const [isMoving, setIsMoving] = useState(false);
  const [isDown, setIsDown] = useState(false);
  const [ghostWidth, setGhostWidth] = useState(0);
  const [ghostHeight, setGhostHeight] = useState(0);
  const [ghostLeft, setGhostLeft] = useState(0);
  const [ghostTop, setGhostTop] = useState(0);
  const el = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (el.current?.getBoundingClientRect && isMoving) {
      const { left, top, width, height } = el.current.getBoundingClientRect();
      setGhostWidth(width);
      setGhostHeight(height);
      setGhostLeft(left);
      setGhostTop(top);

      startMove();

      const gEl = document.getElementById('ghost-block');
      if (gEl?.innerHTML) {
        gEl.innerHTML = el.current.innerHTML;
      }
    }
  }, [el, isMoving]);

  const onMouseMove: MouseEventHandler<HTMLDivElement> = (e) => {
    setGhostLeft(ghostLeft + e.movementX);
    setGhostTop(ghostTop + e.movementY);
  };

  const onMouseUp: MouseEventHandler<HTMLDivElement> = (e) => {
    setIsMoving(false);
    endMove();
  };

  const dragStart = () => {
    if (isDown) {
      setIsMoving(true);
      setIsDown(false);
    }
  };

  return (
    <>
      <div
        ref={el}
        onMouseDown={() => setIsDown(true)}
        onMouseMove={dragStart}
        onMouseUp={() => setIsDown(false)}
        onClick={() => console.log('on click')}
        className={`relative cursor-pointer select-none rounded-lg border border-shade-6 bg-white px-3 py-2 transition-transform duration-100 hover:bg-main-selector `}
      >
        <button className={'absolute right-4 top-2.5 h-5 w-5 rounded hover:bg-surface-2'}>
          <Details2Svg></Details2Svg>
        </button>
        <div className={'flex flex-col gap-3'}>
          {cells.map((cell, index) => (
            <BoardCell
              key={index}
              cellIdentifier={cell.cellIdentifier}
              cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
              fieldController={controller.fieldController}
            ></BoardCell>
          ))}
        </div>
      </div>
      {isMoving && (
        <div
          onMouseMove={onMouseMove}
          onMouseUp={onMouseUp}
          onMouseLeave={onMouseUp}
          id={'ghost-block'}
          className={
            'fixed z-10 rotate-6 scale-105 cursor-pointer select-none rounded-lg border border-shade-6 bg-white px-3 py-2'
          }
          style={{
            width: `${ghostWidth}px`,
            height: `${ghostHeight}px`,
            left: `${ghostLeft}px`,
            top: `${ghostTop}px`,
          }}
        >
          &nbsp;
        </div>
      )}
    </>
  );
};
