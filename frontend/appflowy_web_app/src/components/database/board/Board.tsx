import { useDatabase, useGroupsSelector } from '@/application/database-yjs';
import { Group } from '@/components/database/components/board';
import { CircularProgress } from '@mui/material';
import React from 'react';

export function Board() {
  const database = useDatabase();
  const groups = useGroupsSelector();

  console.log('groups', database);
  if (!database) {
    return (
      <div className={'flex w-full flex-1 flex-col items-center justify-center'}>
        <CircularProgress />
      </div>
    );
  }

  return (
    <div className={'database-board flex w-full flex-1 flex-col'}>
      {groups.map((groupId) => (
        <Group key={groupId} groupId={groupId} />
      ))}
    </div>
  );
}

export default Board;
