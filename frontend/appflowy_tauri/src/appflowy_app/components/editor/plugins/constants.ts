import { EditorNodeType } from '$app/application/document/document.types';

export const BREAK_TO_PARAGRAPH_TYPES = [EditorNodeType.HeadingBlock, EditorNodeType.QuoteBlock, EditorNodeType.Page];

export const SOFT_BREAK_TYPES = [EditorNodeType.CalloutBlock, EditorNodeType.CodeBlock];
