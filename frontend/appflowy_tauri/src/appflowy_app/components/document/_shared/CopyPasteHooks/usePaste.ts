import { useCallback, useContext, useEffect } from 'react';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { pasteThunk } from '$app_reducers/document/async-actions/copyPaste';

export function usePaste(container: HTMLDivElement) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const handlePasteCapture = useCallback(
    (e: ClipboardEvent) => {
      if (!controller) return;
      e.stopPropagation();
      e.preventDefault();
      dispatch(
        pasteThunk({
          controller,
          data: {
            json: e.clipboardData?.getData('application/json') || '',
            text: e.clipboardData?.getData('text/plain') || '',
            html: e.clipboardData?.getData('text/html') || '',
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
