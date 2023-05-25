import { useAppDispatch } from '$app/stores/store';
import { useCallback, useContext } from 'react';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { BlockData, BlockType, NestedBlock } from '$app/interfaces/document';
import { blockConfig } from '$app/constants/document/config';
import { turnToBlockThunk } from '$app_reducers/document/async-actions';

export function useTurnInto({ node, onClose }: { node: NestedBlock; onClose?: () => void }) {
  const dispatch = useAppDispatch();

  const controller = useContext(DocumentControllerContext);

  const turnIntoBlock = useCallback(
    async (type: BlockType, isSelected: boolean, data?: BlockData<any>) => {
      if (!controller || isSelected) {
        onClose?.();
        return;
      }

      const config = blockConfig[type];
      await dispatch(
        turnToBlockThunk({
          id: node.id,
          controller,
          type,
          data: {
            ...config.defaultData,
            delta: node?.data?.delta || [],
            ...data,
          },
        })
      );
      onClose?.();
    },
    [onClose, controller, dispatch, node]
  );

  const turnIntoHeading = useCallback(
    (level: number, isSelected: boolean) => {
      turnIntoBlock(BlockType.HeadingBlock, isSelected, { level });
    },
    [turnIntoBlock]
  );

  return {
    turnIntoBlock,
    turnIntoHeading,
  };
}
