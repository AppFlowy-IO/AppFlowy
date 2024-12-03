import {
  CreateRowDoc,
  FontLayout,
  LineHeightLayout,
  LoadView,
  LoadViewMeta,
} from '@/application/types';
import { createContext, useCallback, useContext, useState } from 'react';
import { BaseRange } from 'slate';

export interface EditorLayoutStyle {
  fontLayout: FontLayout;
  font: string;
  lineHeightLayout: LineHeightLayout;
}

export const defaultLayoutStyle: EditorLayoutStyle = {
  fontLayout: FontLayout.normal,
  font: '',
  lineHeightLayout: LineHeightLayout.normal,
};

export enum EditorVariant {
  publish = 'publish',
  app = 'app',
}

interface Decorate {
  range: BaseRange;
  class_name: string;
}

export interface EditorContextState {
  viewId: string;
  readOnly: boolean;
  layoutStyle?: EditorLayoutStyle;
  codeGrammars?: Record<string, string>;
  addCodeGrammars?: (blockId: string, grammar: string) => void;
  navigateToView?: (viewId: string, blockId?: string) => Promise<void>;
  loadViewMeta?: LoadViewMeta;
  loadView?: LoadView;
  createRowDoc?: CreateRowDoc;
  readSummary?: boolean;
  jumpBlockId?: string;
  onJumpedBlockId?: () => void;
  variant?: EditorVariant;
  onRendered?: () => void;
  decorateState?: Record<string, Decorate>;
  addDecorate?: (range: BaseRange, class_name: string, type: string) => void;
  removeDecorate?: (type: string) => void;
}

export const EditorContext = createContext<EditorContextState>({
  readOnly: true,
  layoutStyle: defaultLayoutStyle,
  codeGrammars: {},
  viewId: '',
});

export const EditorContextProvider = ({ children, ...props }: EditorContextState & { children: React.ReactNode }) => {
  const [decorateState, setDecorateState] = useState<Record<string, Decorate>>({});

  const addDecorate = useCallback((range: BaseRange, class_name: string, type: string) => {
    setDecorateState((prev) => ({
      ...prev,
      [type]: {
        range,
        class_name,
      },
    }));
  }, []);

  const removeDecorate = useCallback((type: string) => {
    setDecorateState((prev) => {
      if (prev[type] === undefined) {
        return prev;
      }

      const newState = { ...prev };

      delete newState[type];
      return newState;
    });
  }, []);

  return <EditorContext.Provider
    value={{
      ...props,
      decorateState,
      addDecorate,
      removeDecorate,
    }}
  >{children}</EditorContext.Provider>;
};

export function useEditorContext () {
  return useContext(EditorContext);
}
