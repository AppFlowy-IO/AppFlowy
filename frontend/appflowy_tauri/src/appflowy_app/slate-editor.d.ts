import { BaseEditor } from 'slate';
import { ReactEditor } from 'slate-react';

interface EditorInlineAttributes {
  bold?: boolean;
  italic?: boolean;
  underline?: boolean;
  strikethrough?: boolean;
  font_color?: string;
  bg_color?: string;
  href?: string;
  code?: boolean;
  formula?: string;
  prism_token?: string;
  temporary?: string;
  mention?: {
    type: string;
    // inline page ref id
    page?: string;
    // reminder date ref id
    date?: string;
  };
}

type CustomElement = {
  children: (CustomText | CustomElement)[];
  type: string;
  level?: number;
  data?: unknown;
  isHidden?: boolean;
  parentId?: string;
  blockId?: string;
  textId?: string;
};

type CustomText = { text: string } & EditorInlineAttributes;

declare module 'slate' {
  interface CustomTypes {
    Editor: BaseEditor & ReactEditor;
    Element: CustomElement;
    Text: CustomText;
  }
}
