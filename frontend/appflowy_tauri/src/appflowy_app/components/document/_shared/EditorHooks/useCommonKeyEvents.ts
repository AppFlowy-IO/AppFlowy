import isHotkey from 'is-hotkey';
import { Keyboard } from '$app/constants/document/keyboard';
import {
  backspaceDeleteActionForBlockThunk,
  leftActionForBlockThunk,
  rightActionForBlockThunk,
  upDownActionForBlockThunk,
} from '$app_reducers/document/async-actions';
import { useMemo } from 'react';
import { useFocused } from '$app/components/document/_shared/SubscribeSelection.hooks';
import { useAppDispatch } from '$app/stores/store';
import { isFormatHotkey, parseFormat } from '$app/utils/document/format';
import { toggleFormatThunk } from '$app_reducers/document/async-actions/format';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { getBlock } from '$app/components/document/_shared/SubscribeNode.hooks';
import Delta from 'quill-delta';

export function useCommonKeyEvents(id: string) {
  const { focused, caretRef } = useFocused(id);
  const { docId, controller } = useSubscribeDocument();

  const dispatch = useAppDispatch();
  const commonKeyEvents = useMemo(() => {
    return [
      {
        // handle backspace and delete key and the caret is at the beginning of the block
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return (
            (isHotkey(Keyboard.keys.BACKSPACE, e) || isHotkey(Keyboard.keys.DELETE, e)) &&
            focused &&
            caretRef.current?.index === 0 &&
            caretRef.current?.length === 0
          );
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          if (!controller) return;
          dispatch(backspaceDeleteActionForBlockThunk({ id, controller }));
        },
      },
      {
        // handle up arrow key and no other key is pressed
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return isHotkey(Keyboard.keys.UP, e);
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          dispatch(upDownActionForBlockThunk({ docId, id }));
        },
      },
      {
        // handle down arrow key and no other key is pressed
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return isHotkey(Keyboard.keys.DOWN, e);
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          dispatch(upDownActionForBlockThunk({ docId, id, down: true }));
        },
      },
      {
        // handle left arrow key and no other key is pressed
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return isHotkey(Keyboard.keys.LEFT, e);
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          e.stopPropagation();
          dispatch(leftActionForBlockThunk({ docId, id }));
        },
      },
      {
        // handle right arrow key and no other key is pressed
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return isHotkey(Keyboard.keys.RIGHT, e);
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          dispatch(rightActionForBlockThunk({ docId, id }));
        },
      },
      {
        // handle format shortcuts
        canHandle: isFormatHotkey,
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
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
    ];
  }, [docId, caretRef, controller, dispatch, focused, id]);

  return commonKeyEvents;
}
