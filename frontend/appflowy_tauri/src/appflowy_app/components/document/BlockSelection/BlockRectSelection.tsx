import React from 'react';
import { useBlockRectSelection } from '$app/components/document/BlockSelection/BlockRectSelection.hooks';

function BlockRectSelection({ container }: { container: HTMLDivElement }) {
  const { isDragging, style } = useBlockRectSelection({
    container,
  });

  if (!isDragging) return null;
  return <div className='z-99 absolute bg-[#00d5ff] opacity-25' style={style} />;
}

export default BlockRectSelection;
