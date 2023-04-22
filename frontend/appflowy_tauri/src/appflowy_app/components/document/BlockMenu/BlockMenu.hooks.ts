import { documentActions } from '@/appflowy_app/stores/reducers/document/slice';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { useRef, useState, useEffect } from 'react';

export function useBlockMenu(nodeId: string, open: boolean) {
  const ref = useRef<HTMLDivElement | null>(null);
  const dispatch = useAppDispatch();
  const [style, setStyle] = useState({ top: '0px', left: '0px' });

  useEffect(() => {
    if (!open) {
      return;
    }
    // set selection when open
    dispatch(documentActions.setSelectionById(nodeId));
    // get node rect
    const rect = document.querySelector(`[data-block-id="${nodeId}"]`)?.getBoundingClientRect();
    if (!rect) return;
    // set menu position
    setStyle({
      top: rect.top + 'px',
      left: rect.left + 'px',
    });
  }, [open, nodeId]);

  return {
    ref,
    style,
  };
}
