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

export function useSelection(id: string) {
  const rangeRef = useRangeRef();
  const { focusCaret } = useFocused(id);
  const decorateProps = useSubscribeDecorate(id);
  const [selection, setSelection] = useState<RangeStatic | undefined>(undefined);
  const dispatch = useAppDispatch();

  const storeRange = useCallback(
    (range: RangeStatic) => {
      dispatch(storeRangeThunk({ id, range }));
    },
    [id, dispatch]
  );

  const onSelectionChange = useCallback(
    (range: RangeStatic | null, _oldRange: RangeStatic | null, _source?: string) => {
      if (!range) return;
      dispatch(
        rangeActions.setCaret({
          id,
          index: range.index,
          length: range.length,
        })
      );
      storeRange(range);
    },
    [id, dispatch, storeRange]
  );

  useEffect(() => {
    if (rangeRef.current && rangeRef.current?.isDragging) return;
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
