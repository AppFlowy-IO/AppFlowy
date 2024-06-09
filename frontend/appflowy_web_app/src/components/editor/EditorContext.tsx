import { FontLayout, LineHeightLayout } from '@/application/collab.type';
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

interface EditorContextState {
  readOnly: boolean;
  layoutStyle: EditorLayoutStyle;
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
