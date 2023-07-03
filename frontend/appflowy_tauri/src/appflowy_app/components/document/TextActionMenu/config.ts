import { TextAction, TextActionMenuProps } from '$app/interfaces/document';

export const defaultTextActionItems = [
  TextAction.Turn,
  TextAction.Link,
  TextAction.Bold,
  TextAction.Italic,
  TextAction.Underline,
  TextAction.Strikethrough,
  TextAction.Code,
  TextAction.Equation,
];
const groupKeys = {
  comment: [],
  format: [
    TextAction.Bold,
    TextAction.Italic,
    TextAction.Underline,
    TextAction.Strikethrough,
    TextAction.Code,
    TextAction.Equation,
  ],
  link: [TextAction.Link],
  turn: [TextAction.Turn],
};

export const multiLineTextActionProps: TextActionMenuProps = {
  customItems: [TextAction.Bold, TextAction.Italic, TextAction.Underline, TextAction.Strikethrough, TextAction.Code],
};
export const multiLineTextActionGroups = [groupKeys.format];
export const textActionGroups = [groupKeys.turn, groupKeys.format, groupKeys.link];
