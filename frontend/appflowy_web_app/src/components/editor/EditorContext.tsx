import { FontLayout, LineHeightLayout, YDoc } from '@/application/collab.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import { createContext, useContext } from 'react';
import Y from 'yjs';

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
  navigateToView?: (viewId: string) => Promise<void>;
  loadViewMeta?: (viewId: string) => Promise<ViewMeta>;
  loadView?: (viewId: string) => Promise<YDoc>;
  getViewRowsMap?: (viewId: string, rowIds: string[]) => Promise<{ rows: Y.Map<YDoc>; destroy: () => void }>;
}

export const EditorContext = createContext<EditorContextState>({
  readOnly: true,
  layoutStyle: defaultLayoutStyle,
});

export const EditorContextProvider = ({ children, ...props }: EditorContextState & { children: React.ReactNode }) => {
  return <EditorContext.Provider value={props}>{children}</EditorContext.Provider>;
};

export function useEditorContext() {
  return useContext(EditorContext);
}
