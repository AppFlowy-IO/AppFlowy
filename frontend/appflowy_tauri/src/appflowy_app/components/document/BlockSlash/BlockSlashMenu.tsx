import React, { useCallback, useMemo } from 'react';
import MenuItem from '$app/components/document/_shared/MenuItem';
import {
  ArrowRight,
  Check,
  DataObject,
  FormatListBulleted,
  FormatListNumbered,
  FormatQuote,
  Lightbulb,
  TextFields,
  Title,
  SafetyDivider,
  Image,
  Functions,
  BackupTableOutlined,
} from '@mui/icons-material';
import {
  BlockData,
  BlockType,
  SlashCommandGroup,
  SlashCommandOption,
  SlashCommandOptionKey,
} from '$app/interfaces/document';
import { useAppDispatch } from '$app/stores/store';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { turnToBlockThunk } from '$app_reducers/document/async-actions';
import { useTranslation } from 'react-i18next';
import { useKeyboardShortcut } from '$app/components/document/BlockSlash/index.hooks';

function BlockSlashMenu({
  id,
  onClose,
  searchText,
  hoverOption,
  onHoverOption,
  container,
}: {
  id: string;
  onClose?: () => void;
  searchText?: string;
  hoverOption?: SlashCommandOption;
  onHoverOption: (option: SlashCommandOption, target: HTMLElement) => void;
  container: HTMLDivElement;
}) {
  const dispatch = useAppDispatch();
  const { t } = useTranslation();
  const { controller } = useSubscribeDocument();

  const handleInsert = useCallback(
    async (type: BlockType, data?: BlockData) => {
      if (!controller) return;
      await dispatch(
        turnToBlockThunk({
          controller,
          id,
          type,
          data,
        })
      );
      onClose?.();
    },
    [controller, dispatch, id, onClose]
  );

  const options: (SlashCommandOption & {
    title: string;
    icon: React.ReactNode;
    group: SlashCommandGroup;
  })[] = useMemo(
    () =>
      [
        {
          key: SlashCommandOptionKey.TEXT,
          type: BlockType.TextBlock,
          title: t('editor.text'),
          icon: <TextFields />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.HEADING_1,
          type: BlockType.HeadingBlock,
          title: t('editor.heading1'),
          icon: <Title />,
          data: {
            level: 1,
          },
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.HEADING_2,
          type: BlockType.HeadingBlock,
          title: t('editor.heading2'),
          icon: <Title />,
          data: {
            level: 2,
          },
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.HEADING_3,
          type: BlockType.HeadingBlock,
          title: t('editor.heading3'),
          icon: <Title />,
          data: {
            level: 3,
          },
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.TODO,
          type: BlockType.TodoListBlock,
          title: t('editor.checkbox'),
          icon: <Check />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.BULLET,
          type: BlockType.BulletedListBlock,
          title: t('editor.bulletedList'),
          icon: <FormatListBulleted />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.NUMBER,
          type: BlockType.NumberedListBlock,
          title: t('editor.numberedList'),
          icon: <FormatListNumbered />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.TOGGLE,
          type: BlockType.ToggleListBlock,
          title: t('document.plugins.toggleList'),
          icon: <ArrowRight />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.QUOTE,
          type: BlockType.QuoteBlock,
          title: t('toolbar.quote'),
          icon: <FormatQuote />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.CALLOUT,
          type: BlockType.CalloutBlock,
          title: 'Callout',
          icon: <Lightbulb />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.DIVIDER,
          type: BlockType.DividerBlock,
          title: t('editor.divider'),
          icon: <SafetyDivider />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.CODE,
          type: BlockType.CodeBlock,
          title: t('document.selectionMenu.codeBlock'),
          icon: <DataObject />,
          group: SlashCommandGroup.MEDIA,
        },
        {
          key: SlashCommandOptionKey.IMAGE,
          type: BlockType.ImageBlock,
          title: t('editor.image'),
          icon: <Image />,
          group: SlashCommandGroup.MEDIA,
        },
        {
          key: SlashCommandOptionKey.EQUATION,
          type: BlockType.EquationBlock,
          title: t('document.plugins.mathEquation.addMathEquation'),
          icon: <Functions />,
          group: SlashCommandGroup.ADVANCED,
        },
        {
          key: SlashCommandOptionKey.GRID_REFERENCE,
          type: BlockType.GridBlock,
          title: t('document.plugins.referencedGrid'),
          icon: <BackupTableOutlined />,
          group: SlashCommandGroup.ADVANCED,
          onClick: () => {
            // do nothing
          },
        },
      ].filter((option) => {
        if (!searchText) return true;
        const match = (text: string) => {
          return text.toLowerCase().includes(searchText.toLowerCase());
        };

        return match(option.title) || match(option.type);
      }),
    [searchText, t]
  );

  const { ref } = useKeyboardShortcut({
    container,
    options,
    handleInsert,
    hoverOption,
  });

  const optionsByGroup = useMemo(() => {
    return options.reduce((acc, option) => {
      if (!acc[option.group]) {
        acc[option.group] = [];
      }

      acc[option.group].push(option);
      return acc;
    }, {} as Record<SlashCommandGroup, typeof options>);
  }, [options]);

  const renderEmptyContent = useCallback(() => {
    return (
      <div className={'m-5 flex items-center justify-center text-text-caption'}>{t('findAndReplace.noResult')}</div>
    );
  }, [t]);

  return (
    <div
      onMouseDown={(e) => {
        e.preventDefault();
        e.stopPropagation();
      }}
      className={'flex h-[100%] max-h-[40vh] w-[324px] min-w-[180px] max-w-[calc(100vw-32px)] flex-col p-1'}
    >
      <div ref={ref} className={'min-h-0 flex-1 overflow-y-auto overflow-x-hidden'}>
        {options.length === 0
          ? renderEmptyContent()
          : Object.entries(optionsByGroup).map(([group, options]) => (
              <div key={group}>
                <div className={'px-2 py-2 text-sm text-text-caption'}>{group}</div>
                <div>
                  {options.map((option) => {
                    return (
                      <MenuItem
                        id={`slash-item-${option.key}`}
                        key={option.key}
                        title={option.title}
                        icon={option.icon}
                        onHover={(e) => {
                          onHoverOption(option, e.currentTarget as HTMLElement);
                        }}
                        isHovered={hoverOption?.key === option.key}
                        onClick={() => {
                          if (!option.onClick) {
                            void handleInsert(option.type, option.data);
                            return;
                          }

                          option.onClick();
                        }}
                      />
                    );
                  })}
                </div>
              </div>
            ))}
      </div>
    </div>
  );
}

export default BlockSlashMenu;
