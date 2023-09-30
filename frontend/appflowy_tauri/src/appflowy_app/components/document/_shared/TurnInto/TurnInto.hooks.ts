import { useAppDispatch } from '$app/stores/store';
import { useCallback } from 'react';
import { BlockData, BlockType, NestedBlock } from '$app/interfaces/document';
import { blockConfig } from '$app/constants/document/config';
import { turnToBlockThunk } from '$app_reducers/document/async-actions';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { setRectSelectionThunk } from '$app_reducers/document/async-actions/rect_selection';

export function useTurnInto({ node, onClose }: { node: NestedBlock; onClose?: () => void }) {
  const dispatch = useAppDispatch();

  const { controller, docId } = useSubscribeDocument();

  const turnIntoBlock = useCallback(
    async (type: BlockType, isSelected: boolean, data?: BlockData<any>) => {
      if (!controller || isSelected) {
        onClose?.();
        return;
      }

      const config = blockConfig[type];
      const defaultData = config.defaultData;
      const updateData = {
        ...defaultData,
        ...data,
      };

      const { payload: newBlockId } = await dispatch(
        turnToBlockThunk({
          id: node.id,
          controller,
          type,
          data: updateData,
        })
      );

      onClose?.();
      dispatch(
        setRectSelectionThunk({
          docId,
          selection: [newBlockId as string],
        })
      );
    },
    [controller, node, dispatch, onClose, docId]
  );

  const turnIntoHeading = useCallback(
    (level: number, isSelected: boolean) => {
      return turnIntoBlock(BlockType.HeadingBlock, isSelected, { level });
    },
    [turnIntoBlock]
  );

  return {
    turnIntoBlock,
    turnIntoHeading,
  };
}
