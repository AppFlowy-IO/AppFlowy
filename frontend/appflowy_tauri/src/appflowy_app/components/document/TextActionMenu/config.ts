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
  TextAction.TextColor,
  TextAction.Highlight,
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
  color: [TextAction.TextColor, TextAction.Highlight],
  turn: [TextAction.Turn],
};

export const multiLineTextActionProps: TextActionMenuProps = {
  customItems: [
    TextAction.Bold,
    TextAction.Italic,
    TextAction.Underline,
    TextAction.Strikethrough,
    TextAction.Code,
    TextAction.TextColor,
    TextAction.Highlight,
  ],
};
export const multiLineTextActionGroups = [groupKeys.format, groupKeys.color];
export const textActionGroups = [groupKeys.turn, groupKeys.format, groupKeys.color, groupKeys.link];
