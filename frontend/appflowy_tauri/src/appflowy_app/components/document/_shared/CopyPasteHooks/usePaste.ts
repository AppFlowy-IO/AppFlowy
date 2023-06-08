import { useCallback, useContext, useEffect } from 'react';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { pasteThunk } from '$app_reducers/document/async-actions/copyPaste';
import { clipboardTypes } from '$app/constants/document/copy_paste';

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
