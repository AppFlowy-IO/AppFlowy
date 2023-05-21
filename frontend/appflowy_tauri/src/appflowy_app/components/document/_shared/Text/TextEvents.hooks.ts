import { useAppDispatch } from '$app/stores/store';
import { useCallback, useContext } from 'react';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { backspaceNodeThunk, setCursorNextLineThunk, setCursorPreLineThunk } from '$app_reducers/document/async-actions';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';
import {
  canHandleBackspaceKey,
  canHandleDownKey,
  canHandleLeftKey,
  canHandleRightKey,
  canHandleUpKey,
} from '$app/utils/document/blocks/text/hotkey';
import { TextBlockKeyEventHandlerParams } from '$app/interfaces/document';
import { ReactEditor } from 'slate-react';

export function useDefaultTextInputEvents(id: string) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const focusPreLineAction = useCallback(
    async (params: { editor: ReactEditor; focusEnd?: boolean }) => {
      await dispatch(setCursorPreLineThunk({ id, ...params }));
    },
    [dispatch, id]
  );

  const focusNextLineAction = useCallback(
    async (params: { editor: ReactEditor; focusStart?: boolean }) => {
      await dispatch(setCursorNextLineThunk({ id, ...params }));
    },
    [dispatch, id]
  );
  return [
    {
      triggerEventKey: keyBoardEventKeyMap.Up,
      canHandle: canHandleUpKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        const [e, _] = args;
        e.preventDefault();
        void focusPreLineAction({
          editor: args[1],
        });
      },
    },
    {
      triggerEventKey: keyBoardEventKeyMap.Down,
      canHandle: canHandleDownKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        const [e, _] = args;
        e.preventDefault();
        void focusNextLineAction({
          editor: args[1],
        });
      },
    },
    {
      triggerEventKey: keyBoardEventKeyMap.Left,
      canHandle: canHandleLeftKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        const [e, _] = args;
        e.preventDefault();
        void focusPreLineAction({
          editor: args[1],
          focusEnd: true,
        });
      },
    },
    {
      triggerEventKey: keyBoardEventKeyMap.Right,
      canHandle: canHandleRightKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        const [e, _] = args;
        e.preventDefault();
        void focusNextLineAction({
          editor: args[1],
          focusStart: true,
        });
      },
    },
    {
      triggerEventKey: keyBoardEventKeyMap.Backspace,
      canHandle: canHandleBackspaceKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        const [e, editor] = args;
        e.preventDefault();
        void (async () => {
          if (!controller) return;
          await dispatch(backspaceNodeThunk({ id, controller, editor }));
        })();
      },
    },
    // Here prevent the default behavior of the enter key
    {
      triggerEventKey: keyBoardEventKeyMap.Enter,
      canHandle: (...args: TextBlockKeyEventHandlerParams) => args[0].key === 'Enter',
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        const [e] = args;
        e.preventDefault();
      },
    },
    // Here prevent the default behavior of the tab key
    {
      triggerEventKey: keyBoardEventKeyMap.Tab,
      canHandle: (...args: TextBlockKeyEventHandlerParams) => args[0].key === 'Tab',
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        const [e] = args;
        e.preventDefault();
      },
    },
  ];
}
