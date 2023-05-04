import { useContext, useMemo } from 'react';
import { BlockData, BlockType, TextBlockKeyEventHandlerParams } from '$app/interfaces/document';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { turnToBlockThunk } from '$app_reducers/document/async-actions';
import { blockConfig } from '$app/constants/document/config';
import { Editor } from 'slate';
import { getBeforeRangeAt } from '$app/utils/document/slate/text';
import {
  getHeadingDataFromEditor,
  getQuoteDataFromEditor,
  getTodoListDataFromEditor,
  getBulletedDataFromEditor,
  getNumberedListDataFromEditor,
} from '$app/utils/document/blocks';

const blockDataFactoryMap: Record<string, (editor: Editor) => BlockData<any> | undefined> = {
  [BlockType.HeadingBlock]: getHeadingDataFromEditor,
  [BlockType.TodoListBlock]: getTodoListDataFromEditor,
  [BlockType.QuoteBlock]: getQuoteDataFromEditor,
  [BlockType.BulletedListBlock]: getBulletedDataFromEditor,
  [BlockType.NumberedListBlock]: getNumberedListDataFromEditor
};

export function useTurnIntoBlock(id: string) {
  const controller = useContext(DocumentControllerContext);
  const dispatch = useAppDispatch();

  const turnIntoBlockEvents = useMemo(() => {
    return Object.entries(blockDataFactoryMap).map(([type, getData]) => {
      const blockType = type as BlockType;
      return {
        triggerEventKey: keyBoardEventKeyMap.Space,
        canHandle: canHandle(blockType),
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          if (!controller) return;
          const [_event, editor] = args;
          const data = getData(editor);
          if (!data) return;
          dispatch(turnToBlockThunk({ id, data, type: blockType, controller }));
        },
      };
    }, []);
  }, [controller, dispatch, id]);

  return {
    turnIntoBlockEvents,
  };
}

function canHandle(type: BlockType) {
  const config = blockConfig[type];

  const regex = config.markdownRegexps;
  // This error will be thrown if the block type is not in the config, and it will happen in development environment
  if (!regex) {
    throw new Error(`canHandle: block type ${type} is not supported`);
  }

  return (...args: TextBlockKeyEventHandlerParams) => {
    const [event, editor] = args;
    const isSpaceKey = event.key === keyBoardEventKeyMap.Space;
    const selection = editor.selection;

    if (!isSpaceKey || !selection) {
      return false;
    }

    const flag = Editor.string(editor, getBeforeRangeAt(editor, selection)).trim();
    if (flag === null) return false;

    return regex.some((r) => r.test(flag));
  };
}
