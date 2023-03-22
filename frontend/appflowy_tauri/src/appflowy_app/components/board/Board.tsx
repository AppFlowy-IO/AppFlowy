import { SettingsSvg } from '../_shared/svg/SettingsSvg';
import { SearchInput } from '../_shared/SearchInput';
import { BoardBlock } from './BoardBlock';
import { NewBoardBlock } from './NewBoardBlock';
import { useDatabase } from '../_shared/database-hooks/useDatabase';
import { ViewLayoutTypePB } from '@/services/backend';
import { DragDropContext } from 'react-beautiful-dnd';
import { useState } from 'react';
import { RowInfo } from '$app/stores/effects/database/row/row_cache';
import { EditRow } from '$app/components/_shared/EditRow/EditRow';

export const Board = ({ viewId }: { viewId: string }) => {
  const { controller, rows, groups, groupByFieldId, onNewRowClick, onDragEnd } = useDatabase(
    viewId,
    ViewLayoutTypePB.Board
  );
  const [showBoardRow, setShowBoardRow] = useState(false);
  const [boardRowInfo, setBoardRowInfo] = useState<RowInfo>();

  const onOpenRow = (rowInfo: RowInfo) => {
    setBoardRowInfo(rowInfo);
    setShowBoardRow(true);
  };

  return (
    <>
      <div className='flex w-full items-center justify-between'>
        <div className={'flex items-center text-xl font-semibold'}>
          <div>{'Kanban'}</div>
          <button className={'ml-2 h-5 w-5'}>
            <SettingsSvg></SettingsSvg>
          </button>
        </div>

        <div className='flex shrink-0 items-center gap-4'>
          <SearchInput />
        </div>
      </div>
      <DragDropContext onDragEnd={onDragEnd}>
        <div className={'relative w-full flex-1 overflow-auto'}>
          <div className={'absolute flex h-full flex-shrink-0 items-start justify-start gap-4'}>
            {controller &&
              groups &&
              groups.map((group, index) => (
                <BoardBlock
                  key={group.groupId}
                  viewId={viewId}
                  controller={controller}
                  group={group}
                  allRows={rows}
                  groupByFieldId={groupByFieldId}
                  onNewRowClick={() => onNewRowClick(index)}
                  onOpenRow={onOpenRow}
                />
              ))}
            <NewBoardBlock onClick={() => console.log('new block')}></NewBoardBlock>
          </div>
        </div>
      </DragDropContext>
      {controller && showBoardRow && boardRowInfo && (
        <EditRow
          onClose={() => setShowBoardRow(false)}
          viewId={viewId}
          controller={controller}
          rowInfo={boardRowInfo}
        ></EditRow>
      )}
    </>
  );
};
