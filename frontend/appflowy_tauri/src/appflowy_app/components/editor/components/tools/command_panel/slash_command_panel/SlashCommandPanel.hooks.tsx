import { EditorNodeType } from '$app/application/document/document.types';
import { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactEditor, useSlate } from 'slate-react';
import { Path } from 'slate';
import { getBlock } from '$app/components/editor/plugins/utils';
import { ReactComponent as TextIcon } from '$app/assets/text.svg';
import { ReactComponent as TodoListIcon } from '$app/assets/todo-list.svg';
import { ReactComponent as Heading1Icon } from '$app/assets/h1.svg';
import { ReactComponent as Heading2Icon } from '$app/assets/h2.svg';
import { ReactComponent as Heading3Icon } from '$app/assets/h3.svg';
import { ReactComponent as BulletedListIcon } from '$app/assets/list.svg';
import { ReactComponent as NumberedListIcon } from '$app/assets/numbers.svg';
import { ReactComponent as QuoteIcon } from '$app/assets/quote.svg';
import { ReactComponent as ToggleListIcon } from '$app/assets/show-menu.svg';
import { ReactComponent as GridIcon } from '$app/assets/grid.svg';
import { DataObjectOutlined, FunctionsOutlined, HorizontalRuleOutlined, MenuBookOutlined } from '@mui/icons-material';
import { CustomEditor } from '$app/components/editor/command';
import { randomEmoji } from '$app/utils/emoji';
import { KeyboardNavigationOption } from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { YjsEditor } from '@slate-yjs/core';

enum SlashCommandPanelTab {
  BASIC = 'basic',
  ADVANCED = 'advanced',
}

export enum SlashOptionType {
  Paragraph,
  TodoList,
  Heading1,
  Heading2,
  Heading3,
  BulletedList,
  NumberedList,
  Quote,
  ToggleList,
  Divider,
  Callout,
  Code,
  Grid,
  MathEquation,
}
const slashOptionGroup = [
  {
    key: SlashCommandPanelTab.BASIC,
    options: [
      SlashOptionType.Paragraph,
      SlashOptionType.TodoList,
      SlashOptionType.Heading1,
      SlashOptionType.Heading2,
      SlashOptionType.Heading3,
      SlashOptionType.BulletedList,
      SlashOptionType.NumberedList,
      SlashOptionType.Quote,
      SlashOptionType.ToggleList,
      SlashOptionType.Divider,
    ],
  },
  {
    key: SlashCommandPanelTab.ADVANCED,
    options: [SlashOptionType.Callout, SlashOptionType.Code, SlashOptionType.Grid, SlashOptionType.MathEquation],
  },
];

const slashOptionMapToEditorNodeType = {
  [SlashOptionType.Paragraph]: EditorNodeType.Paragraph,
  [SlashOptionType.TodoList]: EditorNodeType.TodoListBlock,
  [SlashOptionType.Heading1]: EditorNodeType.HeadingBlock,
  [SlashOptionType.Heading2]: EditorNodeType.HeadingBlock,
  [SlashOptionType.Heading3]: EditorNodeType.HeadingBlock,
  [SlashOptionType.BulletedList]: EditorNodeType.BulletedListBlock,
  [SlashOptionType.NumberedList]: EditorNodeType.NumberedListBlock,
  [SlashOptionType.Quote]: EditorNodeType.QuoteBlock,
  [SlashOptionType.ToggleList]: EditorNodeType.ToggleListBlock,
  [SlashOptionType.Divider]: EditorNodeType.DividerBlock,
  [SlashOptionType.Callout]: EditorNodeType.CalloutBlock,
  [SlashOptionType.Code]: EditorNodeType.CodeBlock,
  [SlashOptionType.Grid]: EditorNodeType.GridBlock,
  [SlashOptionType.MathEquation]: EditorNodeType.EquationBlock,
};

const headingTypeToLevelMap: Record<string, number> = {
  [SlashOptionType.Heading1]: 1,
  [SlashOptionType.Heading2]: 2,
  [SlashOptionType.Heading3]: 3,
};

const headingTypes = [SlashOptionType.Heading1, SlashOptionType.Heading2, SlashOptionType.Heading3];

export function useSlashCommandPanel({
  searchText,
  closePanel,
}: {
  searchText: string;
  closePanel: (deleteText?: boolean) => void;
}) {
  const { t } = useTranslation();
  const editor = useSlate();
  const onConfirm = useCallback(
    (type: SlashOptionType) => {
      const node = getBlock(editor);

      if (!node) return;

      const nodeType = slashOptionMapToEditorNodeType[type];

      if (!nodeType) return;

      const data = {};

      if (headingTypes.includes(type)) {
        Object.assign(data, {
          level: headingTypeToLevelMap[type],
        });
      }

      if (nodeType === EditorNodeType.CalloutBlock) {
        Object.assign(data, {
          icon: randomEmoji(),
        });
      }

      if (nodeType === EditorNodeType.CodeBlock) {
        Object.assign(data, {
          language: 'json',
        });
      }

      closePanel(true);

      const newNode = getBlock(editor);
      const block = CustomEditor.getBlock(editor);

      const path = block ? block[1] : null;

      if (!newNode || !path) return;

      const isEmpty = CustomEditor.isEmptyText(editor, newNode) && newNode.type === EditorNodeType.Paragraph;

      if (!isEmpty) {
        const nextPath = Path.next(path);

        CustomEditor.insertEmptyLine(editor as ReactEditor & YjsEditor, nextPath);
        editor.select(nextPath);
      }

      CustomEditor.turnToBlock(editor, {
        type: nodeType,
        data,
      });
    },
    [editor, closePanel]
  );

  const typeToLabelIconMap = useMemo(() => {
    return {
      [SlashOptionType.Paragraph]: {
        label: t('editor.text'),
        Icon: TextIcon,
      },
      [SlashOptionType.TodoList]: {
        label: t('editor.checkbox'),
        Icon: TodoListIcon,
      },
      [SlashOptionType.Heading1]: {
        label: t('editor.heading1'),
        Icon: Heading1Icon,
      },
      [SlashOptionType.Heading2]: {
        label: t('editor.heading2'),
        Icon: Heading2Icon,
      },
      [SlashOptionType.Heading3]: {
        label: t('editor.heading3'),
        Icon: Heading3Icon,
      },
      [SlashOptionType.BulletedList]: {
        label: t('editor.bulletedList'),
        Icon: BulletedListIcon,
      },
      [SlashOptionType.NumberedList]: {
        label: t('editor.numberedList'),
        Icon: NumberedListIcon,
      },
      [SlashOptionType.Quote]: {
        label: t('editor.quote'),
        Icon: QuoteIcon,
      },
      [SlashOptionType.ToggleList]: {
        label: t('document.plugins.toggleList'),
        Icon: ToggleListIcon,
      },
      [SlashOptionType.Divider]: {
        label: t('editor.divider'),
        Icon: HorizontalRuleOutlined,
      },
      [SlashOptionType.Callout]: {
        label: t('document.plugins.callout'),
        Icon: MenuBookOutlined,
      },
      [SlashOptionType.Code]: {
        label: t('document.selectionMenu.codeBlock'),
        Icon: DataObjectOutlined,
      },
      [SlashOptionType.Grid]: {
        label: t('grid.menuName'),
        Icon: GridIcon,
      },

      [SlashOptionType.MathEquation]: {
        label: t('document.plugins.mathEquation.name'),
        Icon: FunctionsOutlined,
      },
    };
  }, [t]);

  const groupTypeToLabelMap = useMemo(() => {
    return {
      [SlashCommandPanelTab.BASIC]: 'Basic',
      [SlashCommandPanelTab.ADVANCED]: 'Advanced',
    };
  }, []);

  const renderOptionContent = useCallback(
    (type: SlashOptionType) => {
      const Icon = typeToLabelIconMap[type].Icon;

      return (
        <div className={'flex items-center gap-2'}>
          <div className={'flex h-6 w-6 items-center justify-center'}>
            <Icon className={'h-4 w-4'} />
          </div>

          <div className={'flex-1'}>{typeToLabelIconMap[type].label}</div>
        </div>
      );
    },
    [typeToLabelIconMap]
  );

  const options: KeyboardNavigationOption<SlashOptionType | SlashCommandPanelTab>[] = useMemo(() => {
    return slashOptionGroup
      .map((group) => {
        return {
          key: group.key,
          content: <div className={'px-3 pb-1 pt-2 text-sm'}>{groupTypeToLabelMap[group.key]}</div>,
          children: group.options
            .map((type) => {
              return {
                key: type,
                content: renderOptionContent(type),
              };
            })
            .filter((option) => {
              if (!searchText) return true;
              const label = typeToLabelIconMap[option.key].label;

              let newSearchText = searchText;

              if (searchText.startsWith('/')) {
                newSearchText = searchText.slice(1);
              }

              return label.toLowerCase().includes(newSearchText.toLowerCase());
            }),
        };
      })
      .filter((group) => group.children.length > 0);
  }, [searchText, groupTypeToLabelMap, typeToLabelIconMap, renderOptionContent]);

  return {
    options,
    onConfirm,
  };
}
