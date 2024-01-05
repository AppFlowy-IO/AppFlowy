import { EditorNodeType } from '$app/application/document/document.types';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useSlate } from 'slate-react';
import { Transforms } from 'slate';
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

enum SlashCommandPanelTab {
  BASIC = 'basic',
  ADVANCED = 'advanced',
}

enum SlashOptionType {
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
  open,
}: {
  searchText: string;
  closePanel: (deleteText?: boolean) => void;
  open: boolean;
}) {
  const { t } = useTranslation();
  const editor = useSlate();
  const [selectedType, setSelectedType] = useState(SlashOptionType.Paragraph);
  const onClick = useCallback(
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
          language: 'javascript',
        });
      }

      closePanel(true);

      const newNode = getBlock(editor);

      if (!newNode) return;

      const isEmpty = CustomEditor.isEmptyText(editor, newNode);

      if (!isEmpty) {
        Transforms.splitNodes(editor, { always: true });
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
        label: t('document.plugins.todoList'),
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

  const options = useMemo(() => {
    return slashOptionGroup
      .map((group) => {
        return {
          key: group.key,
          label: groupTypeToLabelMap[group.key],
          options: group.options
            .map((type) => {
              return {
                key: type,
                label: typeToLabelIconMap[type].label,
                Icon: typeToLabelIconMap[type].Icon,
                onClick: () => onClick(type),
              };
            })
            .filter((option) => {
              if (!searchText) return true;
              return option.label.toLowerCase().includes(searchText.toLowerCase());
            }),
        };
      })
      .filter((group) => group.options.length > 0);
  }, [groupTypeToLabelMap, onClick, searchText, typeToLabelIconMap]);

  useEffect(() => {
    if (open) {
      const node = getBlock(editor);

      if (!node) return;
      const nodeType = node.type;

      const optionType = Object.entries(slashOptionMapToEditorNodeType).find(([, type]) => type === nodeType);

      if (optionType) {
        setSelectedType(Number(optionType[0]));
      }
    } else {
      setSelectedType(SlashOptionType.Paragraph);
    }
  }, [editor, open]);

  return {
    options,
    selectedType,
    setSelectedType,
  };
}
