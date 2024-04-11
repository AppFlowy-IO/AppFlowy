import { ReactEditor } from 'slate-react';

type CustomElement = {
  children: (CustomText | CustomElement)[];
  type?: string;
  data?: unknown;
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

  interface BaseEditor {
    isEmbed: (element: CustomElement) => boolean;
  }
}
