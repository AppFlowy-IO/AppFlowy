import { useTextInput } from '$app/components/document/_shared/Text/TextInput.hooks';
import isHotkey from 'is-hotkey';
import { useCallback, useContext, useMemo } from 'react';
import { Editor } from 'slate';
import { BlockType, NestedBlock, TextBlockKeyEventHandlerParams } from '$app/interfaces/document';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { splitNodeThunk } from '$app_reducers/document/async-actions';
import { useDefaultTextInputEvents } from '$app/components/document/_shared/Text/useTextEvents';
import { indent, outdent } from '$app/utils/document/blocks/code';

export function useCodeBlock(node: NestedBlock<BlockType.CodeBlock>) {
  const id = node.id;
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);
  const { editor, onChange, value, onDOMBeforeInput } = useTextInput(id);
  const defaultTextInputEvents = useDefaultTextInputEvents(id);

  const customEvents = useMemo(() => {
    return [
      {
        // Here custom tab key event for TextBlock to insert 2 spaces
        triggerEventKey: keyBoardEventKeyMap.Tab,
        canHandle: (...args: TextBlockKeyEventHandlerParams) => isHotkey('tab', args[0]),
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          const [e, editor] = args;
          e.preventDefault();
          indent(editor, 2);
        },
      },
      {
        // Here custom shift+tab key event for TextBlock to delete 2 spaces
        triggerEventKey: keyBoardEventKeyMap.Tab,
        canHandle: (...args: TextBlockKeyEventHandlerParams) => isHotkey('shift+tab', args[0]),
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          const [e, editor] = args;
          e.preventDefault();
          outdent(editor, 2);
        },
      },
      {
        // Here custom enter key event for TextBlock
        triggerEventKey: keyBoardEventKeyMap.Enter,
        canHandle: (...args: TextBlockKeyEventHandlerParams) => isHotkey('enter', args[0]),
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          const [e, editor] = args;
          e.preventDefault();
          Editor.insertText(editor, '\n');
        },
      },
      {
        // Here custom shift+enter key event for TextBlock
        triggerEventKey: keyBoardEventKeyMap.Enter,
        canHandle: (...args: TextBlockKeyEventHandlerParams) => isHotkey('shift+enter', args[0]),
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          const [e, editor] = args;
          e.preventDefault();
          void (async () => {
            if (!controller) return;
            await dispatch(splitNodeThunk({ id, controller, editor }));
          })();
        },
      },
    ];
  }, [controller, dispatch, id]);

  const onKeyDown = useCallback<React.KeyboardEventHandler<HTMLDivElement>>(
    (e) => {
      const keyEvents = [...defaultTextInputEvents, ...customEvents];
      keyEvents.forEach((keyEvent) => {
        // Here we check if the key event can be handled by the current key event
        if (keyEvent.canHandle(e, editor)) {
          keyEvent.handler(e, editor);
        }
      });
    },
    [defaultTextInputEvents, customEvents, editor]
  );

  return {
    editor,
    onKeyDown,
    onChange,
    value,
    onDOMBeforeInput,
  };
}
