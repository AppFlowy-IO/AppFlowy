import { Editor } from 'slate';
import { useTurnIntoBlock } from './TurnIntoEvents.hooks';
import { useCallback, useMemo } from 'react';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';
import {
  canHandleBackspaceKey,
  canHandleDownKey,
  canHandleEnterKey,
  canHandleLeftKey,
  canHandleRightKey,
  canHandleTabKey,
  canHandleUpKey,
  onHandleEnterKey,
  triggerHotkey,
} from '$app/utils/document/blocks/text/hotkey';
import { TextBlockKeyEventHandlerParams } from '$app/interfaces/document';
import { useActions } from './Actions.hooks';

export function useTextBlockKeyEvent(id: string, editor: Editor) {
  const { indentAction, backSpaceAction, splitAction, wrapAction, focusPreLineAction, focusNextLineAction } =
    useActions(id);

  const { turnIntoBlockEvents } = useTurnIntoBlock(id);

  const events = useMemo(() => {
    return [
      {
        triggerEventKey: keyBoardEventKeyMap.Enter,
        canHandle: canHandleEnterKey,
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          onHandleEnterKey(...args, {
            onSplit: splitAction,
            onWrap: wrapAction,
          });
        },
      },
      {
        triggerEventKey: keyBoardEventKeyMap.Tab,
        canHandle: canHandleTabKey,
        handler: (..._args: TextBlockKeyEventHandlerParams) => {
          void indentAction();
        },
      },
      {
        triggerEventKey: keyBoardEventKeyMap.Backspace,
        canHandle: canHandleBackspaceKey,
        handler: (..._args: TextBlockKeyEventHandlerParams) => {
          void backSpaceAction();
        },
      },
      {
        triggerEventKey: keyBoardEventKeyMap.Up,
        canHandle: canHandleUpKey,
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          void focusPreLineAction({
            editor: args[1],
          });
        },
      },
      {
        triggerEventKey: keyBoardEventKeyMap.Down,
        canHandle: canHandleDownKey,
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          void focusNextLineAction({
            editor: args[1],
          });
        },
      },
      {
        triggerEventKey: keyBoardEventKeyMap.Left,
        canHandle: canHandleLeftKey,
        handler: (...args: TextBlockKeyEventHandlerParams) => {
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
          void focusNextLineAction({
            editor: args[1],
            focusStart: true,
          });
        },
      },
    ];
  }, [splitAction, wrapAction, indentAction, backSpaceAction, focusPreLineAction, focusNextLineAction]);

  const onKeyDown = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      // This is list of key events that can be handled by TextBlock
      const keyEvents = [...events, ...turnIntoBlockEvents];

      const matchKeys = keyEvents.filter((keyEvent) => keyEvent.canHandle(event, editor));
      if (matchKeys.length === 0) {
        triggerHotkey(event, editor);
        return;
      }

      event.stopPropagation();
      event.preventDefault();
      matchKeys.forEach((matchKey) => matchKey.handler(event, editor));
    },
    [editor, events, turnIntoBlockEvents]
  );

  return {
    onKeyDown,
  };
}
