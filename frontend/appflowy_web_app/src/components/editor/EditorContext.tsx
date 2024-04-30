import { createContext, useContext } from 'react';

interface EditorContextState {
  readOnly: boolean;
}

export const EditorContext = createContext<EditorContextState>({
  readOnly: true,
});

export const EditorContextProvider = ({ children, ...props }: EditorContextState & { children: React.ReactNode }) => {
  return <EditorContext.Provider value={props}>{children}</EditorContext.Provider>;
};

export function useEditorContext() {
  return useContext(EditorContext);
}
