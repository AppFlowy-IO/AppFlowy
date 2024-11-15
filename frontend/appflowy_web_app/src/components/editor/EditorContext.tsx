import {
  CreateRowDoc,
  FontLayout,
  LineHeightLayout,
  LoadView,
  LoadViewMeta, UIVariant, ViewLayout, View,
} from '@/application/types';
import { TextCount } from '@/utils/word';
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
  variant?: UIVariant;
  onRendered?: () => void;
  decorateState?: Record<string, Decorate>;
  addDecorate?: (range: BaseRange, class_name: string, type: string) => void;
  removeDecorate?: (type: string) => void;
  selectedBlockId?: string;
  setSelectedBlockId?: (blockId?: string) => void;
  addPage?: (parentId: string, layout: ViewLayout, name?: string) => Promise<string>;
  deletePage?: (viewId: string) => Promise<void>;
  openPageModal?: (viewId: string) => void;
  loadViews?: (variant?: UIVariant) => Promise<View[] | undefined>;
  onWordCountChange?: (viewId: string, props: TextCount) => void;
}

export const EditorContext = createContext<EditorContextState>({
  readOnly: true,
  layoutStyle: defaultLayoutStyle,
  codeGrammars: {},
  viewId: '',
});

export const EditorContextProvider = ({ children, ...props }: EditorContextState & { children: React.ReactNode }) => {
  const [decorateState, setDecorateState] = useState<Record<string, Decorate>>({});
  const [selectedBlockId, setSelectedBlockId] = useState<string | undefined>(undefined);

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

  const handleSetSelectedBlockId = useCallback((blockId?: string) => {
    setSelectedBlockId(blockId);
  }, []);

  return <EditorContext.Provider
    value={{
      ...props,
      decorateState,
      addDecorate,
      removeDecorate,
      selectedBlockId,
      setSelectedBlockId: handleSetSelectedBlockId,
    }}
  >{children}</EditorContext.Provider>;
};

export function useEditorContext () {
  return useContext(EditorContext);
}
