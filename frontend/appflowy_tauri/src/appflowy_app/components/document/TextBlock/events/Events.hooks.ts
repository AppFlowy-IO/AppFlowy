import { Editor } from 'slate';
import { useTurnIntoBlock } from './TurnIntoEvents.hooks';
import { useCallback, useContext, useMemo } from 'react';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';
import { BlockType, TextBlockKeyEventHandlerParams } from '$app/interfaces/document';
import isHotkey from 'is-hotkey';
import { indentNodeThunk, outdentNodeThunk, splitNodeThunk } from '$app_reducers/document/async-actions';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { useDefaultTextInputEvents } from '$app/components/document/_shared/Text/TextEvents.hooks';
import { ReactEditor } from 'slate-react';
import { getBeforeRangeAt } from '$app/utils/document/blocks/text/delta';
import { slashCommandActions } from '$app_reducers/document/slice';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';

export function useTextBlockKeyEvent(id: string, editor: ReactEditor) {
  const controller = useContext(DocumentControllerContext);
  const dispatch = useAppDispatch();
  const defaultTextInputEvents = useDefaultTextInputEvents(id);
  const isFocusCurrentNode = useAppSelector((state) => {
    const { anchor, focus } = state.documentRangeSelection;
    if (!anchor || !focus) return false;
    return anchor.id === id && focus.id === id;
  });

  const { node } = useSubscribeNode(id);
  const nodeType = node?.type;

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
      {
        // Here custom slash key event for TextBlock
        triggerEventKey: keyBoardEventKeyMap.Slash,
        canHandle: (...args: TextBlockKeyEventHandlerParams) => {
          const [e, editor] = args;
          if (!editor.selection) return false;

          return isHotkey('/', e) && Editor.string(editor, getBeforeRangeAt(editor, editor.selection)) === '';
        },
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          const [e, _] = args;
          if (!controller) return;
          dispatch(
            slashCommandActions.openSlashCommand({
              blockId: id,
            })
          );
        },
      },
    ],
    [defaultTextInputEvents, controller, dispatch, id, nodeType]
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
