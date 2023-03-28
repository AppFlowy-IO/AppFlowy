import React, { useState } from 'react';
import BlockSideTools from '../BlockSideTools';
import BlockSelection from '../BlockSelection';

export default function Overlay({ container }: { container: HTMLDivElement }) {
  const [isDragging, setDragging] = useState(false);
  return (
    <>
      {isDragging ? null : <BlockSideTools container={container} />}
      <BlockSelection onDragging={setDragging} container={container} />
    </>
  );
}
