import { createContext, useCallback, useContext, useMemo } from 'react';
import { BaseRange, Path } from 'slate';
import { proxy, useSnapshot } from 'valtio';

export interface EditorInlineBlockState {
  formula: {
    popoverOpen: boolean;
    range?: BaseRange;
  };
}
const initialState = {
  formula: {
    popoverOpen: false,
    range: undefined,
  },
};

export const EditorInlineBlockStateContext = createContext<EditorInlineBlockState>(initialState);

export const EditorInlineBlockStateProvider = EditorInlineBlockStateContext.Provider;

export function useInitialEditorInlineBlockState() {
  const state = useMemo(() => {
    return proxy({
      ...initialState,
    });
  }, []);

  return state;
}

export function useEditorInlineBlockState(key: 'formula') {
  const context = useContext(EditorInlineBlockStateContext);

  const state = useSnapshot(context[key]);

  const openPopover = useCallback(() => {
    context[key].popoverOpen = true;
  }, [context, key]);

  const closePopover = useCallback(() => {
    context[key].popoverOpen = false;
  }, [context, key]);

  const setRange = useCallback(
    (at: BaseRange | Path) => {
      const range = Path.isPath(at) ? { anchor: at, focus: at } : at;

      context[key].range = range as BaseRange;
    },
    [context, key]
  );

  return {
    ...state,
    openPopover,
    closePopover,
    setRange,
  };
}
