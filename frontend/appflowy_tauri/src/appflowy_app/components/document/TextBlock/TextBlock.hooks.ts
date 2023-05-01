import { useCallback, useContext, useMemo } from 'react';
import { Editor } from 'slate';
import { TextBlockKeyEventHandlerParams, TextDelta, TextSelection } from '$app/interfaces/document';
import { useTextInput } from '../_shared/TextInput.hooks';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { DocumentControllerContext } from '@/appflowy_app/stores/effects/document/document_controller';
import {
  backspaceNodeThunk,
  indentNodeThunk,
  splitNodeThunk,
  setCursorNextLineThunk,
  setCursorPreLineThunk,
} from '@/appflowy_app/stores/reducers/document/async-actions';
import { documentActions } from '@/appflowy_app/stores/reducers/document/slice';
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
} from '$app/utils/document/slate/hotkey';
import { updateNodeDeltaThunk } from '$app_reducers/document/async-actions/blocks/text/update';
import { useMarkDown } from './useMarkDown.hooks';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';

export function useTextBlock(id: string) {
  const { editor, onChange, value } = useTextInput(id);
  const { onKeyDown } = useTextBlockKeyEvent(id, editor);

  const onKeyDownCapture = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      onKeyDown(event);
    },
    [onKeyDown]
  );

  const onDOMBeforeInput = useCallback((e: InputEvent) => {
    // COMPAT: in Apple, `compositionend` is dispatched after the `beforeinput` for "insertFromComposition".
    // It will cause repeated characters when inputting Chinese.
    // Here, prevent the beforeInput event and wait for the compositionend event to take effect.
    if (e.inputType === 'insertFromComposition') {
      e.preventDefault();
    }
  }, []);

  return {
    onChange,
    onKeyDownCapture,
    onDOMBeforeInput,
    editor,
    value,
  };
}

function useTextBlockKeyEvent(id: string, editor: Editor) {
  const { indentAction, backSpaceAction, splitAction, wrapAction, focusPreLineAction, focusNextLineAction } =
    useActions(id);

  const { markdownEvents } = useMarkDown(id);

  const enterEvent = useMemo(() => {
    return {
      triggerEventKey: keyBoardEventKeyMap.Enter,
      canHandle: canHandleEnterKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        onHandleEnterKey(...args, {
          onSplit: splitAction,
          onWrap: wrapAction,
        });
      },
    };
  }, [splitAction, wrapAction]);

  const tabEvent = useMemo(() => {
    return {
      triggerEventKey: keyBoardEventKeyMap.Tab,
      canHandle: canHandleTabKey,
      handler: (..._args: TextBlockKeyEventHandlerParams) => {
        void indentAction();
      },
    };
  }, [indentAction]);

  const backSpaceEvent = useMemo(() => {
    return {
      triggerEventKey: keyBoardEventKeyMap.Backspace,
      canHandle: canHandleBackspaceKey,
      handler: (..._args: TextBlockKeyEventHandlerParams) => {
        void backSpaceAction();
      },
    };
  }, [backSpaceAction]);

  const upEvent = useMemo(() => {
    return {
      triggerEventKey: keyBoardEventKeyMap.Up,
      canHandle: canHandleUpKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        void focusPreLineAction({
          editor: args[1],
        });
      },
    };
  }, [focusPreLineAction]);

  const downEvent = useMemo(() => {
    return {
      triggerEventKey: keyBoardEventKeyMap.Down,
      canHandle: canHandleDownKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        void focusNextLineAction({
          editor: args[1],
        });
      },
    };
  }, [focusNextLineAction]);

  const leftEvent = useMemo(() => {
    return {
      triggerEventKey: keyBoardEventKeyMap.Left,
      canHandle: canHandleLeftKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        void focusPreLineAction({
          editor: args[1],
          focusEnd: true,
        });
      },
    };
  }, [focusPreLineAction]);

  const rightEvent = useMemo(() => {
    return {
      triggerEventKey: keyBoardEventKeyMap.Right,
      canHandle: canHandleRightKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        void focusNextLineAction({
          editor: args[1],
          focusStart: true,
        });
      },
    };
  }, [focusNextLineAction]);

  const onKeyDown = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      // This is list of key events that can be handled by TextBlock
      const keyEvents = [enterEvent, backSpaceEvent, tabEvent, upEvent, downEvent, leftEvent, rightEvent];

      keyEvents.push(...markdownEvents);
      const matchKeys = keyEvents.filter((keyEvent) => keyEvent.canHandle(event, editor));
      if (matchKeys.length === 0) {
        triggerHotkey(event, editor);
        return;
      }

      event.stopPropagation();
      event.preventDefault();
      matchKeys.forEach((matchKey) => matchKey.handler(event, editor));
    },
    [editor, enterEvent, backSpaceEvent, tabEvent, upEvent, downEvent, leftEvent, rightEvent, markdownEvents]
  );

  return {
    onKeyDown,
  };
}

function useActions(id: string) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const indentAction = useCallback(async () => {
    if (!controller) return;
    await dispatch(
      indentNodeThunk({
        id,
        controller,
      })
    );
  }, [id, controller]);

  const backSpaceAction = useCallback(async () => {
    if (!controller) return;
    await dispatch(backspaceNodeThunk({ id, controller }));
  }, [controller, id]);

  const splitAction = useCallback(
    async (retain: TextDelta[], insert: TextDelta[]) => {
      if (!controller) return;
      await dispatch(splitNodeThunk({ id, retain, insert, controller }));
    },
    [controller, id]
  );

  const wrapAction = useCallback(
    async (delta: TextDelta[], selection: TextSelection) => {
      if (!controller) return;
      await dispatch(updateNodeDeltaThunk({ id, delta, controller }));
      // This is a hack to make sure the selection is updated after next render
      dispatch(documentActions.setTextSelection({ blockId: id, selection }));
    },
    [controller, id]
  );

  const focusPreLineAction = useCallback(
    async (params: { editor: Editor; focusEnd?: boolean }) => {
      await dispatch(setCursorPreLineThunk({ id, ...params }));
    },
    [id]
  );

  const focusNextLineAction = useCallback(
    async (params: { editor: Editor; focusStart?: boolean }) => {
      await dispatch(setCursorNextLineThunk({ id, ...params }));
    },
    [id]
  );

  return {
    indentAction,
    backSpaceAction,
    splitAction,
    wrapAction,
    focusPreLineAction,
    focusNextLineAction,
  };
}
