import { SearchInput } from '../_shared/SearchInput';
import { BoardGroup } from './BoardGroup';
import { useDatabase } from '../_shared/database-hooks/useDatabase';
import { ViewLayoutPB } from '@/services/backend';
import { DragDropContext } from 'react-beautiful-dnd';
import { useState } from 'react';
import { RowInfo } from '$app/stores/effects/database/row/row_cache';
import { EditRow } from '$app/components/_shared/EditRow/EditRow';
import { BoardToolbar } from '$app/components/board/BoardToolbar';

export const Board = ({ viewId, title }: { viewId: string; title: string }) => {
  const { controller, groups, groupByFieldId, onNewRowClick, onDragEnd } = useDatabase(viewId, ViewLayoutPB.Board);
  const [showBoardRow, setShowBoardRow] = useState(false);
  const [boardRowInfo, setBoardRowInfo] = useState<RowInfo>();

  const onOpenRow = (rowInfo: RowInfo) => {
    setBoardRowInfo(rowInfo);
    setShowBoardRow(true);
  };

  return (
    <>
      <div className='flex w-full items-center justify-between'>
        <BoardToolbar title={title} />

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
                <BoardGroup
                  key={group.groupId}
                  viewId={viewId}
                  controller={controller}
                  group={group}
                  groupByFieldId={groupByFieldId}
                  onNewRowClick={() => onNewRowClick(index)}
                  onOpenRow={onOpenRow}
                />
              ))}
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
