import { useDatabase, useGroupsSelector } from '@/application/database-yjs';
import { Group } from '@/components/database/components/board';
import { CircularProgress } from '@mui/material';
import React from 'react';
import { DragDropContext } from 'react-beautiful-dnd';

export function Board() {
  const database = useDatabase();
  const groups = useGroupsSelector();

  if (!database) {
    return (
      <div className={'flex w-full flex-1 flex-col items-center justify-center'}>
        <CircularProgress />
      </div>
    );
  }

  return (
    <DragDropContext
      onDragEnd={() => {
        //
      }}
    >
      <div className={'grid-board flex w-full flex-1 flex-col'}>
        {groups.map((groupId) => (
          <Group key={groupId} groupId={groupId} />
        ))}
      </div>
    </DragDropContext>
  );
}

export default Board;
