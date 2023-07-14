import React from 'react';
import Trash from '$app/components/trash/Trash';

function TrashPage() {
  return (
    <div className='flex h-full flex-col gap-8 px-8 pt-8'>
      <Trash />
    </div>
  );
}

export default TrashPage;
