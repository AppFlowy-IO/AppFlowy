
import { createContext } from 'react';
import { Block, BlockType } from '../interfaces';

export const BlockContext = createContext<{
  id?: string;
  blocksMap?: Record<string, Block>;
} | null>(null);
