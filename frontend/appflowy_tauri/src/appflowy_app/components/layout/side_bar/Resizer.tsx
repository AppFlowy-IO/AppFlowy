import React, { useCallback, useRef } from 'react';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { sidebarActions } from '$app_reducers/sidebar/slice';

const minSidebarWidth = 200;

function Resizer() {
  const dispatch = useAppDispatch();
  const width = useAppSelector((state) => state.sidebar.width);
  const startX = useRef(0);
  const onResize = useCallback(
    (e: MouseEvent) => {
      e.preventDefault();
      const diff = e.clientX - startX.current;
      const newWidth = width + diff;

      if (newWidth < minSidebarWidth) {
        return;
      }

      dispatch(sidebarActions.changeWidth(newWidth));
    },
    [dispatch, width]
  );

  const onResizeEnd = useCallback(() => {
    dispatch(sidebarActions.stopResizing());
    document.removeEventListener('mousemove', onResize);
    document.removeEventListener('mouseup', onResizeEnd);
  }, [onResize, dispatch]);

  const onResizeStart = useCallback(
    (e: React.MouseEvent) => {
      startX.current = e.clientX;
      dispatch(sidebarActions.startResizing());
      document.addEventListener('mousemove', onResize);
      document.addEventListener('mouseup', onResizeEnd);
    },
    [onResize, onResizeEnd, dispatch]
  );

  return (
    <div
      onMouseDown={onResizeStart}
      style={{
        left: `${width - 4}px`,
      }}
      className={'fixed top-0 z-10 h-screen cursor-col-resize'}
    >
      <div className={'h-full w-2 select-none bg-transparent'}></div>
    </div>
  );
}

export default React.memo(Resizer);
