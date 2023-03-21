import { createContext } from "react";
import { TextBlockManager } from '../../block_editor/blocks/text_block';

export const TextBlockContext = createContext<{
  textBlockManager?: TextBlockManager
}>({});
