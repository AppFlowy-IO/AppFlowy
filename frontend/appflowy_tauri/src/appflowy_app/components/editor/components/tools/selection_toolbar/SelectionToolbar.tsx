import React, { memo, useRef } from 'react';
import { useSelectionToolbar } from '$app/components/editor/components/tools/selection_toolbar/SelectionToolbar.hooks';
import SelectionActions from '$app/components/editor/components/tools/selection_toolbar/SelectionActions';
import withErrorBoundary from '$app/components/_shared/error_boundary/withError';

const Toolbar = memo(() => {
  const ref = useRef<HTMLDivElement | null>(null);

  const { visible, restoreSelection, storeSelection, isAcrossBlocks, isIncludeRoot } = useSelectionToolbar(ref);

  return (
    <div
      ref={ref}
      className={
        'selection-toolbar pointer-events-none absolute z-[100] flex min-h-[32px] w-fit flex-grow items-center rounded-lg bg-[var(--fill-toolbar)] px-2 opacity-0 shadow-lg'
      }
      onMouseDown={(e) => {
        // prevent toolbar from taking focus away from editor
        e.preventDefault();
      }}
    >
      <SelectionActions
        isIncludeRoot={isIncludeRoot}
        isAcrossBlocks={isAcrossBlocks}
        storeSelection={storeSelection}
        restoreSelection={restoreSelection}
        visible={visible}
      />
    </div>
  );
});

export const SelectionToolbar = withErrorBoundary(Toolbar);
