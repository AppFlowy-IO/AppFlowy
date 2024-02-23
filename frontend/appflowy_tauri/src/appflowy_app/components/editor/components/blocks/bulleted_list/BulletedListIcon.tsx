import React from 'react';
import { BulletedListNode } from '$app/application/document/document.types';

function BulletedListIcon({ block: _, className }: { block: BulletedListNode; className: string }) {
  return (
    <span
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      contentEditable={false}
      className={`${className} bulleted-icon flex w-[23px] justify-center pr-1 font-medium`}
    />
  );
}

export default BulletedListIcon;
