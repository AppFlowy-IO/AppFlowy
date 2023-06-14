import isHotkey from 'is-hotkey';
import { Keyboard } from '$app/constants/document/keyboard';
import {
  backspaceDeleteActionForBlockThunk,
  leftActionForBlockThunk,
  rightActionForBlockThunk,
  upDownActionForBlockThunk,
} from '$app_reducers/document/async-actions';
import { useContext, useMemo } from 'react';
import { useFocused } from '$app/components/document/_shared/SubscribeSelection.hooks';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { useAppDispatch } from '$app/stores/store';
import { isFormatHotkey, parseFormat } from '$app/utils/document/format';
import { toggleFormatThunk } from '$app_reducers/document/async-actions/format';

export function useCommonKeyEvents(id: string) {
  const { focused, caretRef } = useFocused(id);
  const controller = useContext(DocumentControllerContext);
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
          dispatch(upDownActionForBlockThunk({ id }));
        },
      },
      {
        // handle down arrow key and no other key is pressed
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return isHotkey(Keyboard.keys.DOWN, e);
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          dispatch(upDownActionForBlockThunk({ id, down: true }));
        },
      },
      {
        // handle left arrow key and no other key is pressed
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return isHotkey(Keyboard.keys.LEFT, e);
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          dispatch(leftActionForBlockThunk({ id }));
        },
      },
      {
        // handle right arrow key and no other key is pressed
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          return isHotkey(Keyboard.keys.RIGHT, e);
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          dispatch(rightActionForBlockThunk({ id }));
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
  }, [caretRef, controller, dispatch, focused, id]);
  return commonKeyEvents;
}
