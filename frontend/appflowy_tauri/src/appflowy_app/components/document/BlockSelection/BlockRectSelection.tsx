import React from 'react';
import {
  BlockRectSelectionProps,
  useBlockRectSelection,
} from '$app/components/document/BlockSelection/BlockRectSelection.hooks';

function BlockRectSelection(props: BlockRectSelectionProps) {
  const { isDragging, style } = useBlockRectSelection(props);

  if (!isDragging) return null;
  return <div className='z-99 absolute bg-fill-default opacity-10' style={style} />;
}

export default BlockRectSelection;
