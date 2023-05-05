import { Editor } from 'slate';
import { useTurnIntoBlock } from './TurnIntoEvents.hooks';
import { useCallback, useContext, useMemo } from 'react';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';
import { triggerHotkey } from '$app/utils/document/blocks/text/hotkey';
import { TextBlockKeyEventHandlerParams } from '$app/interfaces/document';
import isHotkey from 'is-hotkey';
import { indentNodeThunk, outdentNodeThunk, splitNodeThunk } from '$app_reducers/document/async-actions';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { useAppDispatch } from '$app/stores/store';
import { useDefaultTextInputEvents } from '$app/components/document/_shared/Text/useTextEvents';

export function useTextBlockKeyEvent(id: string, editor: Editor) {
  const controller = useContext(DocumentControllerContext);
  const dispatch = useAppDispatch();

  const defaultTextInputEvents = useDefaultTextInputEvents(id);

  const { turnIntoBlockEvents } = useTurnIntoBlock(id);

  // Here custom key events for TextBlock
  const events = useMemo(
    () => [
      ...defaultTextInputEvents,
      {
        // Here custom enter key event for TextBlock
        triggerEventKey: keyBoardEventKeyMap.Enter,
        canHandle: (...args: TextBlockKeyEventHandlerParams) => isHotkey('enter', args[0]),
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          const [e, editor] = args;
          e.preventDefault();
          void (async () => {
            if (!controller) return;
            await dispatch(splitNodeThunk({ id, controller, editor }));
          })();
        },
      },
      {
        // Here custom shift+enter key event for TextBlock
        triggerEventKey: keyBoardEventKeyMap.Enter,
        canHandle: (...args: TextBlockKeyEventHandlerParams) => isHotkey('shift+enter', args[0]),
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          const [e, editor] = args;
          e.preventDefault();
          Editor.insertText(editor, '\n');
        },
      },
      {
        // Here custom tab key event for TextBlock
        triggerEventKey: keyBoardEventKeyMap.Tab,
        canHandle: (...args: TextBlockKeyEventHandlerParams) => isHotkey('tab', args[0]),
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          const [e, _] = args;
          e.preventDefault();
          if (!controller) return;
          dispatch(
            indentNodeThunk({
              id,
              controller,
            })
          );
        },
      },
      {
        // Here custom shift+tab key event for TextBlock
        triggerEventKey: keyBoardEventKeyMap.Tab,
        canHandle: (...args: TextBlockKeyEventHandlerParams) => isHotkey('shift+tab', args[0]),
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          const [e, _] = args;
          e.preventDefault();
          if (!controller) return;
          dispatch(
            outdentNodeThunk({
              id,
              controller,
            })
          );
        },
      },
    ],
    [defaultTextInputEvents, controller, dispatch, id]
  );

  const onKeyDown = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      // This is list of key events that can be handled by TextBlock
      const keyEvents = [...events, ...turnIntoBlockEvents];

      const matchKeys = keyEvents.filter((keyEvent) => keyEvent.canHandle(event, editor));
      if (matchKeys.length === 0) {
        triggerHotkey(event, editor);
        return;
      }

      matchKeys.forEach((matchKey) => matchKey.handler(event, editor));
    },
    [editor, events, turnIntoBlockEvents]
  );

  return {
    onKeyDown,
  };
}
