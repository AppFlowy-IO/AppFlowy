import { createContext, useCallback, useContext, useMemo } from 'react';
import { proxy, useSnapshot } from 'valtio';
import { EditorNodeType } from '$app/application/document/document.types';

export interface EditorBlockState {
  [EditorNodeType.ImageBlock]: {
    popoverOpen: boolean;
    blockId?: string;
  };
  [EditorNodeType.EquationBlock]: {
    popoverOpen: boolean;
    blockId?: string;
  };
}

const initialState = {
  [EditorNodeType.ImageBlock]: {
    popoverOpen: false,
    blockId: undefined,
  },
  [EditorNodeType.EquationBlock]: {
    popoverOpen: false,
    blockId: undefined,
  },
};

export const EditorBlockStateContext = createContext<EditorBlockState>(initialState);

export const EditorBlockStateProvider = EditorBlockStateContext.Provider;

export function useEditorInitialBlockState() {
  const state = useMemo(() => {
    return proxy({
      ...initialState,
    });
  }, []);

  return state;
}

export function useEditorBlockState(key: EditorNodeType.ImageBlock | EditorNodeType.EquationBlock) {
  const context = useContext(EditorBlockStateContext);

  return useSnapshot(context[key]);
}

export function useEditorBlockDispatch() {
  const context = useContext(EditorBlockStateContext);

  const openPopover = useCallback(
    (key: EditorNodeType.ImageBlock | EditorNodeType.EquationBlock, blockId: string) => {
      context[key].popoverOpen = true;
      context[key].blockId = blockId;
    },
    [context]
  );

  const closePopover = useCallback(
    (key: EditorNodeType.ImageBlock | EditorNodeType.EquationBlock) => {
      context[key].popoverOpen = false;
      context[key].blockId = undefined;
    },
    [context]
  );

  return {
    openPopover,
    closePopover,
  };
}
