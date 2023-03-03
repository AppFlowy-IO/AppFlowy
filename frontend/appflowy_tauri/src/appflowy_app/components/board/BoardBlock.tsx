import { Details2Svg } from '../_shared/svg/Details2Svg';
import AddSvg from '../_shared/svg/AddSvg';
import { DatabaseFieldMap, IDatabaseColumn, IDatabaseRow } from '../../stores/reducers/database/slice';
import { BoardCard } from './BoardCard';
import { RowInfo } from '../../stores/effects/database/row/row_cache';
import { useEffect } from 'react';
import { useRow } from '../_shared/database-hooks/useRow';
import { DatabaseController } from '../../stores/effects/database/database_controller';

export const BoardBlock = ({
  viewId,
  controller,
  title,
  groupingFieldId,
  rows,
  startMove,
  endMove,
}: {
  viewId: string;
  controller: DatabaseController;
  title: string;
  groupingFieldId: string;
  rows: readonly RowInfo[];
  startMove: (id: string) => void;
  endMove: () => void;
}) => {
  return (
    <div className={'flex h-full w-[250px] flex-col rounded-lg bg-surface-1'}>
      <div className={'flex items-center justify-between p-4'}>
        <div className={'flex items-center gap-2'}>
          <span>{title}</span>
          <span className={'text-shade-4'}>()</span>
        </div>
        <div className={'flex items-center gap-2'}>
          <button className={'h-5 w-5 rounded hover:bg-surface-2'}>
            <Details2Svg></Details2Svg>
          </button>
          <button className={'h-5 w-5 rounded hover:bg-surface-2'}>
            <AddSvg></AddSvg>
          </button>
        </div>
      </div>
      <div className={'flex flex-1 flex-col gap-1 overflow-auto px-2'}>
        {rows.map((row, index) => (
          <BoardCard
            viewId={viewId}
            controller={controller}
            key={index}
            groupingFieldId={groupingFieldId}
            row={row}
            startMove={() => startMove(row.row.id)}
            endMove={() => endMove()}
          ></BoardCard>
        ))}
      </div>
      <div className={'p-2'}>
        <button className={'flex w-full items-center gap-2 rounded-lg px-2 py-2 hover:bg-surface-2'}>
          <span className={'h-5 w-5'}>
            <AddSvg></AddSvg>
          </span>
          <span>New</span>
        </button>
      </div>
    </div>
  );
};
