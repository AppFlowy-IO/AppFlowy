import { useCallback, useContext, useEffect } from 'react';
import { useAppDispatch } from '$app/stores/store';
import { pasteThunk } from '$app_reducers/document/async-actions/copy_paste';
import { clipboardTypes } from '$app/constants/document/copy_paste';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function usePaste(container: HTMLDivElement) {
  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();
  const handlePasteCapture = useCallback(
    (e: ClipboardEvent) => {
      if (!controller) return;
      e.stopPropagation();
      e.preventDefault();
      dispatch(
        pasteThunk({
          controller,
          data: {
            json: e.clipboardData?.getData(clipboardTypes.JSON) || '',
            text: e.clipboardData?.getData(clipboardTypes.TEXT) || '',
            html: e.clipboardData?.getData(clipboardTypes.HTML) || '',
          },
        })
      );
    },
    [controller, dispatch]
  );

  useEffect(() => {
    container.addEventListener('paste', handlePasteCapture, true);
    return () => {
      container.removeEventListener('paste', handlePasteCapture, true);
    };
  }, [container, handlePasteCapture]);
}
