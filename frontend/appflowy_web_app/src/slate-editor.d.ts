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
  font_family?: string;
  formula?: string;
  prism_token?: string;
  class_name?: string;
  mention?: {
    type: string;
    // inline page ref id
    page_id?: string;
    // reminder date ref id
    date?: string;
    reminder_id?: string;
    reminder_option?: string;
  };
}

type CustomElement = {
  children: (CustomText | CustomElement)[];
  type?: string;
  data?: unknown;
  blockId?: string;
  textId?: string;
  relationId?: string;
};

type CustomText = { text: string } & EditorInlineAttributes;

declare module 'slate' {
  interface CustomTypes {
    Editor: BaseEditor & ReactEditor;
    Element: CustomElement;
    Text: CustomText;
  }

  interface BaseEditor {
    isEmbed: (element: CustomElement) => boolean;
  }
}
