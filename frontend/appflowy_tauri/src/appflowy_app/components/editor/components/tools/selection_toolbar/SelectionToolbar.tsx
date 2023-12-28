import React, { memo, useRef } from 'react';
import { useSelectionToolbar } from '$app/components/editor/components/tools/selection_toolbar/SelectionToolbar.hooks';
import SelectionActions from '$app/components/editor/components/tools/selection_toolbar/SelectionActions';

export const SelectionToolbar = memo(() => {
  const ref = useRef<HTMLDivElement | null>(null);

  const { visible, ...toolbarProps } = useSelectionToolbar(ref);

  return (
    <div
      ref={ref}
      className={
        'selection-toolbar pointer-events-none absolute z-[100] flex w-fit flex-grow transform items-center rounded-lg bg-[var(--fill-toolbar)] p-2 opacity-0 shadow-lg transition-opacity'
      }
      onMouseDown={(e) => {
        // prevent toolbar from taking focus away from editor
        e.preventDefault();
      }}
      onMouseUp={(e) => {
        e.stopPropagation();
      }}
    >
      <SelectionActions {...toolbarProps} toolbarVisible={visible} />
    </div>
  );
});
