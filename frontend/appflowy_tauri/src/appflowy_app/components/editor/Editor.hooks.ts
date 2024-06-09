import { createContext, useContext } from 'react';

export const EditorIdContext = createContext('');

export const EditorIdProvider = EditorIdContext.Provider;

export function useEditorId() {
  return useContext(EditorIdContext);
}
