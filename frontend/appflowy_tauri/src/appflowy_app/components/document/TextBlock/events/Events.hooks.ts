import { Editor } from 'slate';
import { useTurnIntoBlock } from './TurnIntoEvents.hooks';
import { useCallback, useContext, useMemo } from 'react';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';
import { TextBlockKeyEventHandlerParams } from '$app/interfaces/document';
import isHotkey from 'is-hotkey';
import { indentNodeThunk, outdentNodeThunk, splitNodeThunk } from '$app_reducers/document/async-actions';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { useDefaultTextInputEvents } from '$app/components/document/_shared/Text/TextEvents.hooks';
import { ReactEditor } from 'slate-react';

export function useTextBlockKeyEvent(id: string, editor: ReactEditor) {
  const controller = useContext(DocumentControllerContext);
  const dispatch = useAppDispatch();
  const defaultTextInputEvents = useDefaultTextInputEvents(id);
  const isFocusCurrentNode = useAppSelector((state) => {
    const { anchor, focus } = state.documentRangeSelection;
    if (!anchor || !focus) return false;
    return anchor.id === id && focus.id === id;
  });

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
      if (!isFocusCurrentNode) {
        event.preventDefault();
        return;
      }

      event.stopPropagation();
      // This is list of key events that can be handled by TextBlock
      const keyEvents = [...events, ...turnIntoBlockEvents];

      const matchKeys = keyEvents.filter((keyEvent) => keyEvent.canHandle(event, editor));

      matchKeys.forEach((matchKey) => matchKey.handler(event, editor));
    },
    [editor, events, turnIntoBlockEvents, isFocusCurrentNode]
  );

  return {
    onKeyDown,
  };
}
