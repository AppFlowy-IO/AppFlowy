import React, { useRef } from 'react';
import { useBlockActionsToolbar } from './BlockActionsToolbar.hooks';
import BlockActions from '$app/components/editor/components/tools/block_actions/BlockActions';

import { getBlockCssProperty } from '$app/components/editor/components/tools/block_actions/utils';

export function BlockActionsToolbar() {
  const ref = useRef<HTMLDivElement | null>(null);

  const { node } = useBlockActionsToolbar(ref);

  const cssProperty = node && getBlockCssProperty(node);

  return (
    <div
      ref={ref}
      contentEditable={false}
      className={`block-actions ${cssProperty} absolute z-10 flex w-[64px] flex-grow transform items-center justify-end px-1 opacity-0 transition-opacity`}
      onMouseDown={(e) => {
        // prevent toolbar from taking focus away from editor
        e.preventDefault();
        e.stopPropagation();
      }}
      onMouseUp={(e) => {
        e.stopPropagation();
      }}
    >
      {/* Ensure the toolbar in middle */}
      <div className={'invisible'}>0</div>
      {<BlockActions node={node || undefined} />}
    </div>
  );
}
