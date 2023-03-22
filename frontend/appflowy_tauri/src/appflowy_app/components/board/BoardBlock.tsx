import { Details2Svg } from '../_shared/svg/Details2Svg';
import AddSvg from '../_shared/svg/AddSvg';
import { BoardCard } from './BoardCard';
import { RowInfo } from '../../stores/effects/database/row/row_cache';
import { DatabaseController } from '../../stores/effects/database/database_controller';
import { RowPB } from '@/services/backend';

export const BoardBlock = ({
  viewId,
  controller,
  title,
  rows,
  allRows,
}: {
  viewId: string;
  controller: DatabaseController;
  title: string;
  rows: RowPB[];
  allRows: readonly RowInfo[];
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
        {rows.map((row_pb, index) => {
          const row = allRows.find((r) => r.row.id === row_pb.id);
          return row ? (
            <BoardCard viewId={viewId} controller={controller} key={index} rowInfo={row}></BoardCard>
          ) : (
            <span key={index}></span>
          );
        })}
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
