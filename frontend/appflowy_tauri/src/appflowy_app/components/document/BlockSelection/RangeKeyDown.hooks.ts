import { useCallback, useContext, useMemo } from 'react';
import { Keyboard } from '$app/constants/document/keyboard';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { arrowActionForRangeThunk, deleteRangeAndInsertThunk } from '$app_reducers/document/async-actions';
import Delta from 'quill-delta';
import isHotkey from 'is-hotkey';
import { deleteRangeAndInsertEnterThunk } from '$app_reducers/document/async-actions/range';
import { useRangeRef } from '$app/components/document/_shared/SubscribeSelection.hooks';
import { isPrintableKeyEvent } from '$app/utils/document/action';

export function useRangeKeyDown() {
  const rangeRef = useRangeRef();

  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);
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
          return isPrintableKeyEvent(e);
        },
        handler: (e: KeyboardEvent) => {
          if (!controller) return;
          const insertDelta = new Delta().insert(e.key);
          dispatch(
            deleteRangeAndInsertThunk({
              controller,
              insertDelta,
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
            })
          );
        },
      },
    ],
    [controller, dispatch]
  );

  const onKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (!rangeRef.current) {
        return;
      }
      const { anchor, focus } = rangeRef.current;
      if (anchor?.id === focus?.id) {
        return;
      }
      e.stopPropagation();
      e.preventDefault();
      const filteredEvents = interceptEvents.filter((event) => event.canHandle(e));
      filteredEvents.forEach((event) => event.handler(e));
    },
    [interceptEvents, rangeRef]
  );

  return onKeyDown;
}
