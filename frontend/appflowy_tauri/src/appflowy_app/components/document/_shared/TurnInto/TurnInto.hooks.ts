import { useAppDispatch } from '$app/stores/store';
import { useCallback } from 'react';
import { BlockData, BlockType, NestedBlock } from '$app/interfaces/document';
import { blockConfig } from '$app/constants/document/config';
import { turnToBlockThunk } from '$app_reducers/document/async-actions';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import Delta from 'quill-delta';
import { getDeltaText } from '$app/utils/document/delta';
import { rangeActions, rectSelectionActions } from '$app_reducers/document/slice';
import { setRectSelectionThunk } from '$app_reducers/document/async-actions/rect_selection';

export function useTurnInto({ node, onClose }: { node: NestedBlock; onClose?: () => void }) {
  const dispatch = useAppDispatch();

  const { controller, docId } = useSubscribeDocument();

  const getTurnIntoData = useCallback(
    (targetType: BlockType, sourceNode: NestedBlock) => {
      if (targetType === sourceNode.type) return;
      const config = blockConfig[targetType];
      const defaultData = config.defaultData;
      const data: BlockData<any> = {
        ...defaultData,
        delta: sourceNode?.data?.delta || [],
      };

      if (targetType === BlockType.EquationBlock) {
        data.formula = getDeltaText(new Delta(sourceNode.data.delta));
        delete data.delta;
      }

      if (sourceNode.type === BlockType.EquationBlock) {
        data.delta = [
          {
            insert: node.data.formula,
          },
        ];
      }

      return data;
    },
    [node.data.formula]
  );

  const turnIntoBlock = useCallback(
    async (type: BlockType, isSelected: boolean, data?: BlockData<any>) => {
      if (!controller || isSelected) {
        onClose?.();
        return;
      }

      const updateData = {
        ...getTurnIntoData(type, node),
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
    [controller, getTurnIntoData, node, dispatch, onClose, docId]
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
