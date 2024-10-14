import ToolbarActions from '@/components/editor/components/toolbar/selection-toolbar/ToolbarActions';
import { SelectionToolbarContext, useToolbarPosition, useVisible } from './SelectionToolbar.hooks';
import React, { useEffect, useRef } from 'react';

export function SelectionToolbar () {
  const { visible, forceShow } = useVisible();
  const ref = useRef<HTMLDivElement | null>(null);
  const {
    hideToolbar,
    showToolbar,
  } = useToolbarPosition();

  useEffect(() => {
    const el = ref.current;

    if (!el) return;
    if (!visible) {
      hideToolbar(el);
      return;
    }

    showToolbar(el);
  }, [hideToolbar, showToolbar, visible]);

  return (
    <SelectionToolbarContext.Provider value={{ visible, forceShow }}>
      <div
        ref={ref}
        className={
          'selection-toolbar pointer-events-none absolute z-[100] flex min-h-[32px] w-fit flex-grow items-center rounded-lg bg-[var(--fill-toolbar)] px-2 opacity-0 shadow-lg'
        }
        onMouseDown={(e) => {
          // prevent toolbar from taking focus away from editor
          e.preventDefault();
          e.stopPropagation();
        }}
      >
        <ToolbarActions />
      </div>
    </SelectionToolbarContext.Provider>
  );
}

export default SelectionToolbar;