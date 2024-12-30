import ControlActions from '@/components/editor/components/toolbar/block-controls/ControlActions';
import { useHoverControls } from '@/components/editor/components/toolbar/block-controls/HoverControls.hooks';
import React, { useState } from 'react';

export function HoverControls () {
  const [openMenu, setOpenMenu] = useState(false);

  const { ref, cssProperty, hoveredBlockId } = useHoverControls({
    disabled: openMenu,
  });

  return (
    <>
      <div
        ref={ref}
        data-testid={'hover-controls'}
        contentEditable={false}
        // Prevent the toolbar from being selected
        onMouseDown={(e) => {
          e.preventDefault();
        }}
        className={`absolute hover-controls w-[64px] px-1 z-10 opacity-0 flex items-center justify-end ${cssProperty}`}
      >
        {/* Ensure the toolbar in middle */}
        <div className={`invisible hover-controls-placeholder`}>$</div>
        <ControlActions
          setOpenMenu={setOpenMenu}
          blockId={hoveredBlockId}
        />
      </div>

    </>
  );
}

export default HoverControls;