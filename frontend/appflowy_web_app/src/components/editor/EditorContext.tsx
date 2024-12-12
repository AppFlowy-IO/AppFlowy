import {
  CreateRowDoc,
  FontLayout,
  LineHeightLayout,
  LoadView,
  LoadViewMeta, UIVariant, View, CreatePagePayload,
} from '@/application/types';
import { TextCount } from '@/utils/word';
import { createContext, useCallback, useContext, useState } from 'react';
import { BaseRange, Range } from 'slate';

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

export interface Decorate {
  range: BaseRange;
  class_name: string;
}

export interface EditorContextState {
  viewId: string;
  readOnly: boolean;
  layoutStyle?: EditorLayoutStyle;
  codeGrammars?: Record<string, string>;
  addCodeGrammars?: (blockId: string, grammar: string) => void;
  navigateToView?: (viewId: string, blockOrRowId?: string) => Promise<void>;
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

  selectedBlockIds?: string[];
  setSelectedBlockIds?: React.Dispatch<React.SetStateAction<string[]>>;
  addPage?: (parentId: string, payload: CreatePagePayload) => Promise<string>;
  deletePage?: (viewId: string) => Promise<void>;
  openPageModal?: (viewId: string) => void;
  loadViews?: (variant?: UIVariant) => Promise<View[] | undefined>;
  onWordCountChange?: (viewId: string, props: TextCount) => void;
  uploadFile?: (file: File) => Promise<string>;
}

export const EditorContext = createContext<EditorContextState>({
  readOnly: true,
  layoutStyle: defaultLayoutStyle,
  codeGrammars: {},
  viewId: '',
});

export const EditorContextProvider = ({ children, ...props }: EditorContextState & { children: React.ReactNode }) => {
  const [decorateState, setDecorateState] = useState<Record<string, Decorate>>({});
  const [selectedBlockIds, setSelectedBlockIds] = useState<string[]>([]);

  const addDecorate = useCallback((range: BaseRange, class_name: string, type: string) => {
    setDecorateState((prev) => {
      const oldValue = prev[type];

      if (oldValue && Range.equals(oldValue.range, range) && oldValue.class_name === class_name) {
        return prev;
      }

      return {
        ...prev,
        [type]: {
          range,
          class_name,
        },
      };
    });
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
      setSelectedBlockIds,
      selectedBlockIds,
    }}
  >{children}</EditorContext.Provider>;
};

export function useEditorContext() {
  return useContext(EditorContext);
}

export function useBlockSelected(blockId: string) {
  const { selectedBlockIds } = useEditorContext();

  return selectedBlockIds?.includes(blockId);
}
