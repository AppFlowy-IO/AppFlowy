
import { createContext } from 'react';
import { Block } from '../interfaces';

export const BlockContext = createContext<{
  id?: string;
}>({});


const documentBlocksMap = new Map<string, Record<string, Block>>();
export function setDocumentBlocksMap(id: string, blocksMap: Record<string, Block>) {
  documentBlocksMap.set(id, blocksMap);
}

export function getDocumentBlocksMap(id: string) {
  return documentBlocksMap.get(id);
}

