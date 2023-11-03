import { useCallback, useEffect } from 'react';
import { copyThunk } from '$app_reducers/document/async-actions/copy_paste';
import { useAppDispatch } from '$app/stores/store';
import { BlockCopyData } from '$app/interfaces/document';
import { clipboardTypes } from '$app/constants/document/copy_paste';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useCopy(container: HTMLDivElement) {
  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();

  const onCopy = useCallback(
    (e: ClipboardEvent, isCut: boolean) => {
      if (!controller) return;
      e.stopPropagation();
      e.preventDefault();
      const setClipboardData = (data: BlockCopyData) => {
        e.clipboardData?.setData(clipboardTypes.JSON, data.json);
        e.clipboardData?.setData(clipboardTypes.TEXT, data.text);
        e.clipboardData?.setData(clipboardTypes.HTML, data.html);
      };

      void dispatch(
        copyThunk({
          setClipboardData,
          controller,
          isCut,
        })
      );
    },
    [controller, dispatch]
  );

  const handleCopyCapture = useCallback(
    (e: ClipboardEvent) => {
      onCopy(e, false);
    },
    [onCopy]
  );

  const handleCutCapture = useCallback(
    (e: ClipboardEvent) => {
      onCopy(e, true);
    },
    [onCopy]
  );

  useEffect(() => {
    container.addEventListener('copy', handleCopyCapture, true);
    container.addEventListener('cut', handleCutCapture, true);

    return () => {
      container.removeEventListener('copy', handleCopyCapture, true);
      container.removeEventListener('cut', handleCutCapture, true);
    };
  }, [container, handleCopyCapture, handleCutCapture]);
}
