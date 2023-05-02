import React, { useState } from 'react';
import BlockSideToolbar from '../BlockSideToolbar';
import BlockSelection from '../BlockSelection';

export default function Overlay({ container }: { container: HTMLDivElement }) {
  const [isDragging, setDragging] = useState(false);
  return (
    <>
      {isDragging ? null : <BlockSideToolbar container={container} />}
      <BlockSelection onDragging={setDragging} container={container} />
    </>
  );
}
