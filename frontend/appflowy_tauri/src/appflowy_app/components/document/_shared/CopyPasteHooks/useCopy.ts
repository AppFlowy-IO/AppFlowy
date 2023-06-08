import { useCallback, useContext, useEffect } from 'react';
import { copyThunk } from '$app_reducers/document/async-actions/copyPaste';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { BlockCopyData } from '$app/interfaces/document';
import { clipboardTypes } from '$app/constants/document/copy_paste';

export function useCopy(container: HTMLDivElement) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const handleCopyCapture = useCallback(
    (e: ClipboardEvent) => {
      if (!controller) return;
      e.stopPropagation();
      e.preventDefault();
      const setClipboardData = (data: BlockCopyData) => {
        e.clipboardData?.setData(clipboardTypes.JSON, data.json);
        e.clipboardData?.setData(clipboardTypes.TEXT, data.text);
        e.clipboardData?.setData(clipboardTypes.HTML, data.html);
      };
      dispatch(
        copyThunk({
          setClipboardData,
        })
      );
    },
    [controller, dispatch]
  );

  useEffect(() => {
    container.addEventListener('copy', handleCopyCapture, true);
    return () => {
      container.removeEventListener('copy', handleCopyCapture, true);
    };
  }, [container, handleCopyCapture]);
}
