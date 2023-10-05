import { useCallback, useMemo } from 'react';
import { Keyboard } from '$app/constants/document/keyboard';
import { useAppDispatch } from '$app/stores/store';
import { arrowActionForRangeThunk, deleteRangeAndInsertThunk } from '$app_reducers/document/async-actions';
import Delta from 'quill-delta';
import isHotkey from 'is-hotkey';
import { deleteRangeAndInsertEnterThunk } from '$app_reducers/document/async-actions/range';
import { useRangeRef } from '$app/components/document/_shared/SubscribeSelection.hooks';
import { isPrintableKeyEvent } from '$app/utils/document/action';
import { toggleFormatThunk } from '$app_reducers/document/async-actions/format';
import { isFormatHotkey, parseFormat } from '$app/utils/document/format';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useRangeKeyDown() {
  const rangeRef = useRangeRef();

  const dispatch = useAppDispatch();
  const { docId, controller } = useSubscribeDocument();

  const interceptEvents = useMemo(
    () => [
      {
        // handle backspace and delete
        canHandle: (e: KeyboardEvent) => {
          return isHotkey(Keyboard.keys.BACKSPACE, e) || isHotkey(Keyboard.keys.DELETE, e);
        },
        handler: (_: KeyboardEvent) => {
          if (!controller) return;
          dispatch(
            deleteRangeAndInsertThunk({
              controller,
            })
          );
        },
      },
      {
        // handle char input
        canHandle: (e: KeyboardEvent) => {
          return isPrintableKeyEvent(e) && !e.shiftKey && !e.ctrlKey && !e.metaKey;
        },
        handler: (e: KeyboardEvent) => {
          if (!controller) return;
          dispatch(
            deleteRangeAndInsertThunk({
              controller,
              insertChar: e.key,
            })
          );
        },
      },
      {
        // handle shift + enter
        canHandle: (e: KeyboardEvent) => {
          return isHotkey(Keyboard.keys.SHIFT_ENTER, e);
        },
        handler: (e: KeyboardEvent) => {
          if (!controller) return;
          dispatch(
            deleteRangeAndInsertEnterThunk({
              controller,
              shiftKey: true,
            })
          );
        },
      },
      {
        // handle enter
        canHandle: (e: KeyboardEvent) => {
          return isHotkey(Keyboard.keys.ENTER, e);
        },
        handler: (e: KeyboardEvent) => {
          if (!controller) return;
          dispatch(
            deleteRangeAndInsertEnterThunk({
              controller,
              shiftKey: false,
            })
          );
        },
      },
      {
        // handle arrows
        canHandle: (e: KeyboardEvent) => {
          return (
            isHotkey(Keyboard.keys.LEFT, e) ||
            isHotkey(Keyboard.keys.RIGHT, e) ||
            isHotkey(Keyboard.keys.UP, e) ||
            isHotkey(Keyboard.keys.DOWN, e)
          );
        },
        handler: (e: KeyboardEvent) => {
          dispatch(
            arrowActionForRangeThunk({
              key: e.key,
              docId,
            })
          );
        },
      },
      {
        // handle format shortcuts
        canHandle: isFormatHotkey,
        handler: (e: KeyboardEvent) => {
          if (!controller) return;
          const format = parseFormat(e);

          if (!format) return;
          dispatch(
            toggleFormatThunk({
              format,
              controller,
            })
          );
        },
      },
    ],
    [controller, dispatch, docId]
  );

  const onKeyDownCapture = useCallback(
    (e: KeyboardEvent) => {
      if (!rangeRef.current) {
        return;
      }

      const { anchor, focus } = rangeRef.current;

      if (!anchor || !focus) return;

      if (anchor.id === focus.id) {
        return;
      }

      e.stopPropagation();
      const filteredEvents = interceptEvents.filter((event) => event.canHandle(e));
      const lastIndex = filteredEvents.length - 1;

      if (lastIndex < 0) {
        return;
      }

      const lastEvent = filteredEvents[lastIndex];

      if (!lastEvent) return;
      e.preventDefault();
      lastEvent.handler(e);
    },
    [interceptEvents, rangeRef]
  );

  return onKeyDownCapture;
}
