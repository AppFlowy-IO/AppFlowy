import { FontLayout, GetViewRowsMap, LineHeightLayout, LoadView, LoadViewMeta } from '@/application/types';
import { createContext, useContext } from 'react';

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

export interface EditorContextState {
  readOnly: boolean;
  layoutStyle?: EditorLayoutStyle;
  codeGrammars?: Record<string, string>;
  addCodeGrammars?: (blockId: string, grammar: string) => void;
  navigateToView?: (viewId: string) => Promise<void>;
  loadViewMeta?: LoadViewMeta;
  loadView?: LoadView;
  getViewRowsMap?: GetViewRowsMap;
  readSummary?: boolean;
  jumpBlockId?: string;
  onJumpedBlockId?: () => void;
}

export const EditorContext = createContext<EditorContextState>({
  readOnly: true,
  layoutStyle: defaultLayoutStyle,
  codeGrammars: {},
});

export const EditorContextProvider = ({ children, ...props }: EditorContextState & { children: React.ReactNode }) => {
  return <EditorContext.Provider value={props}>{children}</EditorContext.Provider>;
};

export function useEditorContext () {
  return useContext(EditorContext);
}
