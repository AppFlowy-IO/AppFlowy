import React, { useState } from 'react';
import BlockSideTools from '../BlockSideTools';
import BlockSelection from '../BlockSelection';
import { BlockEditor } from '@/appflowy_app/block_editor';

export default function Overlay({ blockEditor, container }: { container: HTMLDivElement; blockEditor: BlockEditor }) {
  const [isDragging, setDragging] = useState(false);
  return (
    <>
      {isDragging ? null : <BlockSideTools blockEditor={blockEditor} container={container} />}
      <BlockSelection onDragging={setDragging} blockEditor={blockEditor} container={container} />
    </>
  );
}
