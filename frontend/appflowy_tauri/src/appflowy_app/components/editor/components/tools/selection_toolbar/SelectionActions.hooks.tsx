import {
  EditorInlineAttributes,
  EditorInlineNodeType,
  EditorMarkFormat,
  EditorNodeType,
  EditorStyleFormat,
  EditorTurnFormat,
  HeadingNode,
} from '$app/application/document/document.types';

import { ReactComponent as BoldSvg } from '$app/assets/bold.svg';
import { ReactComponent as UnderlineSvg } from '$app/assets/underline.svg';
import { ReactComponent as StrikeThroughSvg } from '$app/assets/strikethrough.svg';
import { ReactComponent as ItalicSvg } from '$app/assets/italic.svg';
import { ReactComponent as CodeSvg } from '$app/assets/inline-code.svg';
import { ReactComponent as Heading1Svg } from '$app/assets/h1.svg';
import { ReactComponent as Heading2Svg } from '$app/assets/h2.svg';
import { ReactComponent as Heading3Svg } from '$app/assets/h3.svg';
import { ReactComponent as ParagraphSvg } from '$app/assets/text.svg';
import { ReactComponent as TodoListSvg } from '$app/assets/todo-list.svg';
import { ReactComponent as QuoteSvg } from '$app/assets/quote.svg';
import { ReactComponent as ToggleListSvg } from '$app/assets/show-menu.svg';
import { ReactComponent as NumberedListSvg } from '$app/assets/numbers.svg';
import { ReactComponent as BulletedListSvg } from '$app/assets/list.svg';
import { ReactComponent as LinkSvg } from '$app/assets/link.svg';

import FormatColorFillIcon from '@mui/icons-material/FormatColorFill';
import FormatColorTextIcon from '@mui/icons-material/FormatColorText';
import Functions from '@mui/icons-material/Functions';

import { ReactEditor } from 'slate-react';
import React, { useCallback, useMemo } from 'react';
import { getBlock } from '$app/components/editor/plugins/utils';
import { FontColorPicker, BgColorPicker } from '$app/components/editor/components/tools/_shared';
import { useTranslation } from 'react-i18next';
import { addMark, Editor } from 'slate';
import { CustomEditor } from '$app/components/editor/command';

const markFormatActions = [
  EditorMarkFormat.Underline,
  EditorMarkFormat.Bold,
  EditorMarkFormat.Italic,
  EditorMarkFormat.StrikeThrough,
  EditorMarkFormat.Code,
  EditorMarkFormat.Formula,
];

const styleFormatActions = [EditorStyleFormat.Href, EditorStyleFormat.FontColor, EditorStyleFormat.BackgroundColor];

const textFormatActions = [
  EditorTurnFormat.Paragraph,
  EditorTurnFormat.Heading1,
  EditorTurnFormat.Heading2,
  EditorTurnFormat.Heading3,
];

const blockFormatActions = [
  EditorTurnFormat.TodoList,
  EditorTurnFormat.Quote,
  EditorTurnFormat.ToggleList,
  EditorTurnFormat.NumberedList,
  EditorTurnFormat.BulletedList,
];

export interface SelectionAction {
  format: EditorMarkFormat | EditorTurnFormat | EditorStyleFormat;
  Icon: React.FunctionComponent<React.SVGProps<SVGSVGElement>>;
  text: string;
  isActive: () => boolean;
  onClick: ((e: React.MouseEvent<HTMLButtonElement, MouseEvent>) => void) | (() => void);
  alwaysInSingleLine?: boolean;
}

export function useSelectionMarkFormatActions(editor: ReactEditor) {
  const { t } = useTranslation();
  const formatMark = useCallback(
    (format: EditorMarkFormat) => {
      CustomEditor.toggleMark(editor, {
        key: format,
        value: true,
      });
    },
    [editor]
  );
  const isFormatActive = useCallback(
    (format: EditorMarkFormat) => {
      return CustomEditor.isMarkActive(editor, format);
    },
    [editor]
  );

  return useMemo(() => {
    const map = {
      [EditorMarkFormat.Bold]: {
        format: EditorMarkFormat.Bold,
        Icon: BoldSvg,
        text: t('editor.bold'),
        isActive: () => {
          return isFormatActive(EditorMarkFormat.Bold);
        },
        onClick: () => {
          formatMark(EditorMarkFormat.Bold);
        },
      },
      [EditorMarkFormat.Italic]: {
        format: EditorMarkFormat.Italic,
        Icon: ItalicSvg,
        text: t('editor.italic'),
        isActive: () => {
          return isFormatActive(EditorMarkFormat.Italic);
        },
        onClick: () => {
          formatMark(EditorMarkFormat.Italic);
        },
      },
      [EditorMarkFormat.Underline]: {
        format: EditorMarkFormat.Underline,
        Icon: UnderlineSvg,
        text: t('editor.underline'),
        isActive: () => {
          return isFormatActive(EditorMarkFormat.Underline);
        },
        onClick: () => {
          formatMark(EditorMarkFormat.Underline);
        },
      },
      [EditorMarkFormat.StrikeThrough]: {
        format: EditorMarkFormat.StrikeThrough,
        Icon: StrikeThroughSvg,
        text: t('editor.strikethrough'),
        isActive: () => {
          return isFormatActive(EditorMarkFormat.StrikeThrough);
        },
        onClick: () => {
          formatMark(EditorMarkFormat.StrikeThrough);
        },
      },
      [EditorMarkFormat.Code]: {
        format: EditorMarkFormat.Code,
        Icon: CodeSvg,
        text: t('editor.embedCode'),
        isActive: () => {
          return isFormatActive(EditorMarkFormat.Code);
        },
        onClick: () => {
          formatMark(EditorMarkFormat.Code);
        },
      },
      [EditorMarkFormat.Formula]: {
        format: EditorMarkFormat.Formula,
        Icon: Functions,
        alwaysInSingleLine: true,
        text: t('document.plugins.createInlineMathEquation'),
        isActive: () => {
          return CustomEditor.isFormulaActive(editor);
        },
        onClick: () => {
          CustomEditor.toggleInlineElement(editor, EditorInlineNodeType.Formula);
        },
      },
    };

    return markFormatActions.map((format) => map[format]) as SelectionAction[];
  }, [editor, formatMark, isFormatActive, t]);
}

export function useBlockFormatActionMap(editor: ReactEditor) {
  const { t } = useTranslation();

  return useMemo(() => {
    const toHeading = (level: number) => {
      CustomEditor.turnToBlock(editor, {
        type: EditorNodeType.HeadingBlock,
        data: {
          level,
        },
      });
    };

    return {
      [EditorTurnFormat.Paragraph]: {
        format: EditorTurnFormat.Paragraph,
        text: t('editor.text'),
        onClick: () => {
          const node = getBlock(editor);

          if (!node) return;

          CustomEditor.turnToBlock(editor, {
            type: EditorNodeType.Paragraph,
          });
        },
        Icon: ParagraphSvg,
        isActive: () => {
          return CustomEditor.isBlockActive(editor, EditorTurnFormat.Paragraph);
        },
      },
      [EditorTurnFormat.Heading1]: {
        format: EditorTurnFormat.Heading1,
        text: t('editor.heading1'),
        Icon: Heading1Svg,
        onClick: () => {
          toHeading(1);
        },
        isActive: () => {
          const node = getBlock(editor) as HeadingNode;

          if (!node) return false;
          const isBlock = CustomEditor.isBlockActive(editor, EditorNodeType.HeadingBlock);

          return isBlock && node.data.level === 1;
        },
      },
      [EditorTurnFormat.Heading2]: {
        format: EditorTurnFormat.Heading2,
        Icon: Heading2Svg,
        text: t('editor.heading2'),
        onClick: () => {
          toHeading(2);
        },
        isActive: () => {
          const node = getBlock(editor) as HeadingNode;

          if (!node) return false;
          const isBlock = CustomEditor.isBlockActive(editor, EditorNodeType.HeadingBlock);

          return isBlock && node.data.level === 2;
        },
      },
      [EditorTurnFormat.Heading3]: {
        format: EditorTurnFormat.Heading3,
        Icon: Heading3Svg,
        text: t('editor.heading3'),
        onClick: () => {
          toHeading(3);
        },
        isActive: () => {
          const node = getBlock(editor) as HeadingNode;

          if (!node) return false;
          const isBlock = CustomEditor.isBlockActive(editor, EditorNodeType.HeadingBlock);

          return isBlock && node.data.level === 3;
        },
      },
      [EditorTurnFormat.TodoList]: {
        format: EditorTurnFormat.TodoList,
        text: t('document.plugins.todoList'),
        onClick: () => {
          const node = getBlock(editor);

          if (!node) return;

          CustomEditor.turnToBlock(editor, {
            type: EditorNodeType.TodoListBlock,
          });
        },
        Icon: TodoListSvg,
        isActive: () => {
          const entry = CustomEditor.getBlock(editor);

          if (!entry) return false;

          const node = entry[0];

          return node.type === EditorNodeType.TodoListBlock;
        },
      },
      [EditorTurnFormat.Quote]: {
        format: EditorTurnFormat.Quote,
        text: t('editor.quote'),
        onClick: () => {
          const node = getBlock(editor);

          if (!node) return;
          CustomEditor.turnToBlock(editor, {
            type: EditorNodeType.QuoteBlock,
          });
        },
        Icon: QuoteSvg,
        isActive: () => {
          const entry = CustomEditor.getBlock(editor);

          if (!entry) return false;

          const node = entry[0];

          return node.type === EditorNodeType.QuoteBlock;
        },
      },
      [EditorTurnFormat.ToggleList]: {
        format: EditorTurnFormat.ToggleList,
        text: t('document.plugins.toggleList'),
        onClick: () => {
          const node = getBlock(editor);

          if (!node) return;

          CustomEditor.turnToBlock(editor, {
            type: EditorNodeType.ToggleListBlock,
          });
        },
        Icon: ToggleListSvg,
        isActive: () => {
          const entry = CustomEditor.getBlock(editor);

          if (!entry) return false;

          const node = entry[0];

          return node.type === EditorNodeType.ToggleListBlock;
        },
      },
      [EditorTurnFormat.NumberedList]: {
        format: EditorTurnFormat.NumberedList,
        text: t('document.plugins.numberedList'),
        onClick: () => {
          const node = getBlock(editor);

          if (!node) return;

          CustomEditor.turnToBlock(editor, {
            type: EditorNodeType.NumberedListBlock,
          });
        },
        Icon: NumberedListSvg,
        isActive: () => {
          const entry = CustomEditor.getBlock(editor);

          if (!entry) return false;

          const node = entry[0];

          return node.type === EditorNodeType.NumberedListBlock;
        },
      },
      [EditorTurnFormat.BulletedList]: {
        format: EditorTurnFormat.BulletedList,
        text: t('document.plugins.bulletedList'),
        onClick: () => {
          const node = getBlock(editor);

          if (!node) return;

          CustomEditor.turnToBlock(editor, {
            type: EditorNodeType.BulletedListBlock,
          });
        },
        Icon: BulletedListSvg,
        isActive: () => {
          const entry = CustomEditor.getBlock(editor);

          if (!entry) return false;

          const node = entry[0];

          return node.type === EditorNodeType.BulletedListBlock;
        },
      },
    };
  }, [editor, t]);
}

export function useSelectionTextFormatActions(editor: ReactEditor): SelectionAction[] {
  const map = useBlockFormatActionMap(editor);

  return useMemo(() => {
    return textFormatActions.map((action) => map[action]);
  }, [map]);
}

export function useBlockFormatActions(editor: ReactEditor): SelectionAction[] {
  const map = useBlockFormatActionMap(editor);

  return useMemo(() => {
    return blockFormatActions.map((action) => map[action]);
  }, [map]);
}

export function useSelectionStyleFormatActions(
  editor: ReactEditor,
  {
    onPopoverOpen,
    onFocus,
    onBlur,
    onPopoverClose,
  }: {
    onPopoverOpen: (format: EditorStyleFormat, target: HTMLButtonElement) => void;
    onPopoverClose: () => void;
    onFocus: () => void;
    onBlur: () => void;
  }
) {
  const handleStyleChange = useCallback(
    (format: EditorStyleFormat, value: string) => {
      onPopoverClose();
      addMark(editor, format, value);
    },
    [editor, onPopoverClose]
  );

  const subMenu = useCallback(
    (format: EditorStyleFormat) => {
      if (!editor.selection) return null;
      const entry = editor.node(editor.selection);
      const node = entry[0] as EditorInlineAttributes;

      switch (format) {
        case EditorStyleFormat.Href:
          return null;
        case EditorStyleFormat.BackgroundColor:
          return (
            <BgColorPicker
              onBlur={onBlur}
              onFocus={onFocus}
              color={node.bg_color}
              onChange={(color) => handleStyleChange(format, color)}
            />
          );
        case EditorStyleFormat.FontColor:
          return (
            <FontColorPicker
              onBlur={onBlur}
              onFocus={onFocus}
              color={node.font_color}
              onChange={(color) => handleStyleChange(format, color)}
            />
          );
      }
    },
    [editor, handleStyleChange, onBlur, onFocus]
  );
  const { t } = useTranslation();

  const options = useMemo(() => {
    const handleClick = (e: React.MouseEvent<HTMLButtonElement, MouseEvent>, format: EditorStyleFormat) => {
      onPopoverOpen(format, e.currentTarget);
    };

    const map = {
      [EditorStyleFormat.Href]: {
        format: EditorStyleFormat.Href,
        Icon: LinkSvg,
        text: t('editor.link'),
        alwaysInSingleLine: true,
        isActive: () => {
          return CustomEditor.isMarkActive(editor, EditorStyleFormat.Href);
        },
        onClick: () => {
          if (!editor.selection) return;
          const text = Editor.string(editor, editor.selection);

          addMark(editor, EditorStyleFormat.Href, text);
        },
      },
      [EditorStyleFormat.FontColor]: {
        format: EditorStyleFormat.FontColor,
        Icon: FormatColorTextIcon,
        text: t('editor.textColor'),
        isActive: () => {
          return CustomEditor.isMarkActive(editor, EditorStyleFormat.FontColor);
        },
        onClick: (e: React.MouseEvent<HTMLButtonElement, MouseEvent>) => handleClick(e, EditorStyleFormat.FontColor),
      },
      [EditorStyleFormat.BackgroundColor]: {
        format: EditorStyleFormat.BackgroundColor,
        Icon: FormatColorFillIcon,
        text: t('editor.backgroundColor'),
        isActive: () => {
          return CustomEditor.isMarkActive(editor, EditorStyleFormat.BackgroundColor);
        },
        onClick: (e: React.MouseEvent<HTMLButtonElement, MouseEvent>) =>
          handleClick(e, EditorStyleFormat.BackgroundColor),
      },
    };

    return styleFormatActions.map((format) => map[format]) as SelectionAction[];
  }, [t, editor, onPopoverOpen]);

  return {
    options,
    handleStyleChange,
    subMenu,
  };
}
