import { useCallback, useEffect, useState } from 'react';
import { RangeStatic } from 'quill';
import { useAppDispatch } from '$app/stores/store';
import { rangeActions } from '$app_reducers/document/slice';
import {
  useFocused,
  useRangeRef,
  useSubscribeDecorate,
} from '$app/components/document/_shared/SubscribeSelection.hooks';
import { storeRangeThunk } from '$app_reducers/document/async-actions/range';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useSelection(id: string) {
  const rangeRef = useRangeRef();
  const { focusCaret } = useFocused(id);
  const decorateProps = useSubscribeDecorate(id);
  const [selection, setSelection] = useState<RangeStatic | undefined>(undefined);
  const dispatch = useAppDispatch();
  const { docId } = useSubscribeDocument();

  const storeRange = useCallback(
    (range: RangeStatic) => {
      dispatch(storeRangeThunk({ id, range, docId }));
    },
    [docId, id, dispatch]
  );

  const onSelectionChange = useCallback(
    (range: RangeStatic | null, _oldRange: RangeStatic | null, _source?: string) => {
      if (!range) return;
      dispatch(
        rangeActions.setCaret({
          docId,
          caret: {
            id,
            index: range.index,
            length: range.length,
          },
        })
      );
      storeRange(range);
    },
    [docId, id, dispatch, storeRange]
  );

  useEffect(() => {
    if (rangeRef.current) {
      const { isDragging, anchor, focus } = rangeRef.current;
      const mouseDownFocused = anchor?.point.x === focus?.point.x && anchor?.point.y === focus?.point.y;

      if (isDragging && !mouseDownFocused) {
        return;
      }
    }

    if (!focusCaret) {
      setSelection(undefined);
      return;
    }

    setSelection({
      index: focusCaret.index,
      length: focusCaret.length,
    });
  }, [rangeRef, focusCaret]);

  return {
    onSelectionChange,
    selection,
    ...decorateProps,
  };
}
