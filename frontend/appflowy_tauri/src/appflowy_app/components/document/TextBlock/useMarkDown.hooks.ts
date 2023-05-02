import { useCallback, useContext, useMemo } from 'react';
import { TextBlockKeyEventHandlerParams } from '$app/interfaces/document';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';
import {
  canHandleToHeadingBlock,
  canHandleToCheckboxBlock,
  canHandleToQuoteBlock,
} from '$app/utils/document/slate/markdown';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { turnToHeadingBlockThunk } from '$app_reducers/document/async-actions/blocks/heading';
import { turnToTodoListBlockThunk } from '$app_reducers/document/async-actions/blocks/todo_list';
import { turnToQuoteBlockThunk } from '$app_reducers/document/async-actions/blocks/quote';

export function useMarkDown(id: string) {
  const { toHeadingBlockAction, toCheckboxBlockAction, toQuoteBlockAction } = useActions(id);
  const toHeadingBlockEvent = useMemo(() => {
    return {
      triggerEventKey: keyBoardEventKeyMap.Space,
      canHandle: canHandleToHeadingBlock,
      handler: toHeadingBlockAction,
    };
  }, [toHeadingBlockAction]);

  const toCheckboxBlockEvent = useMemo(() => {
    return {
      triggerEventKey: keyBoardEventKeyMap.Space,
      canHandle: canHandleToCheckboxBlock,
      handler: toCheckboxBlockAction,
    };
  }, [toCheckboxBlockAction]);

  const toQuoteBlockEvent = useMemo(() => {
    return {
      triggerEventKey: keyBoardEventKeyMap.Space,
      canHandle: canHandleToQuoteBlock,
      handler: toQuoteBlockAction,
    };
  }, [toQuoteBlockAction]);

  const markdownEvents = useMemo(
    () => [toHeadingBlockEvent, toCheckboxBlockEvent, toQuoteBlockEvent],
    [toHeadingBlockEvent, toCheckboxBlockEvent, toQuoteBlockEvent]
  );

  return {
    markdownEvents,
  };
}

function useActions(id: string) {
  const controller = useContext(DocumentControllerContext);
  const dispatch = useAppDispatch();
  const toHeadingBlockAction = useCallback(
    (...args: TextBlockKeyEventHandlerParams) => {
      if (!controller) return;
      const [_event, editor] = args;
      dispatch(turnToHeadingBlockThunk({ id, editor, controller }));
    },
    [controller, dispatch, id]
  );

  const toCheckboxBlockAction = useCallback(
    (...args: TextBlockKeyEventHandlerParams) => {
      if (!controller) return;
      const [_event, editor] = args;
      dispatch(turnToTodoListBlockThunk({ id, controller, editor }));
    },
    [controller, dispatch, id]
  );

  const toQuoteBlockAction = useCallback(
    (...args: TextBlockKeyEventHandlerParams) => {
      if (!controller) return;
      const [_event, editor] = args;
      dispatch(turnToQuoteBlockThunk({ id, controller, editor }));
    },
    [controller, dispatch, id]
  );

  return {
    toHeadingBlockAction,
    toCheckboxBlockAction,
    toQuoteBlockAction,
  };
}
