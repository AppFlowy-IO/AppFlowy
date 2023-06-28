import { useCallback, useRef, useState } from 'react';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppDispatch } from '$app/stores/store';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions';
import { rectSelectionActions } from '$app_reducers/document/slice';
import { setRectSelectionThunk } from '$app_reducers/document/async-actions/rect_selection';

export function useEquationBlock(node: NestedBlock<BlockType.EquationBlock>) {
  const { controller, docId } = useSubscribeDocument();
  const id = node.id;
  const dispatch = useAppDispatch();
  const formula = node.data.formula;
  const ref = useRef<HTMLDivElement>(null);
  const [value, setValue] = useState(formula);

  const [anchorPosition, setAnchorPosition] = useState<{
    top: number;
    left: number;
  }>();
  const open = Boolean(anchorPosition);

  const onChange = useCallback((newVal: string) => {
    setValue(newVal);
  }, []);

  const onOpenPopover = useCallback(() => {
    setValue(formula);
    const rect = ref.current?.getBoundingClientRect();

    if (!rect) return;
    setAnchorPosition({
      top: rect.top + rect.height,
      left: rect.left + rect.width / 2,
    });
  }, [formula]);

  const onClosePopover = useCallback(() => {
    setAnchorPosition(undefined);
    dispatch(
      setRectSelectionThunk({
        docId,
        selection: [id],
      })
    );
  }, [dispatch, id, docId]);

  const onConfirm = useCallback(async () => {
    await dispatch(
      updateNodeDataThunk({
        id,
        data: {
          formula: value,
        },
        controller,
      })
    );
    onClosePopover();
  }, [dispatch, id, value, controller, onClosePopover]);

  return {
    open,
    ref,
    value,
    onChange,
    onOpenPopover,
    onClosePopover,
    onConfirm,
    anchorPosition,
  };
}
