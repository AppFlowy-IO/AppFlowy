import React, { useCallback, useEffect, useMemo, useRef } from 'react';
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
import { slashCommandActions } from '$app_reducers/document/slice';
import { Keyboard } from '$app/constants/document/keyboard';
import { selectOptionByUpDown } from '$app/utils/document/menu';
import { turnToBlockThunk } from '$app_reducers/document/async-actions';

function BlockSlashMenu({
  id,
  onClose,
  searchText,
  hoverOption,
  container,
}: {
  id: string;
  onClose?: () => void;
  searchText?: string;
  hoverOption?: SlashCommandOption;
  container: HTMLDivElement;
}) {
  const dispatch = useAppDispatch();
  const ref = useRef<HTMLDivElement | null>(null);
  const { docId, controller } = useSubscribeDocument();
  const handleInsert = useCallback(
    async (type: BlockType, data?: BlockData<any>) => {
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
          title: 'Text',
          icon: <TextFields />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.HEADING_1,
          type: BlockType.HeadingBlock,
          title: 'Heading 1',
          icon: <Title />,
          data: {
            level: 1,
          },
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.HEADING_2,
          type: BlockType.HeadingBlock,
          title: 'Heading 2',
          icon: <Title />,
          data: {
            level: 2,
          },
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.HEADING_3,
          type: BlockType.HeadingBlock,
          title: 'Heading 3',
          icon: <Title />,
          data: {
            level: 3,
          },
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.TODO,
          type: BlockType.TodoListBlock,
          title: 'To-do list',
          icon: <Check />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.BULLET,
          type: BlockType.BulletedListBlock,
          title: 'Bulleted list',
          icon: <FormatListBulleted />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.NUMBER,
          type: BlockType.NumberedListBlock,
          title: 'Numbered list',
          icon: <FormatListNumbered />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.TOGGLE,
          type: BlockType.ToggleListBlock,
          title: 'Toggle list',
          icon: <ArrowRight />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.QUOTE,
          type: BlockType.QuoteBlock,
          title: 'Quote',
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
          title: 'Divider',
          icon: <SafetyDivider />,
          group: SlashCommandGroup.BASIC,
        },
        {
          key: SlashCommandOptionKey.CODE,
          type: BlockType.CodeBlock,
          title: 'Code',
          icon: <DataObject />,
          group: SlashCommandGroup.MEDIA,
        },
        {
          key: SlashCommandOptionKey.IMAGE,
          type: BlockType.ImageBlock,
          title: 'Image',
          icon: <Image />,
          group: SlashCommandGroup.MEDIA,
        },
        {
          key: SlashCommandOptionKey.EQUATION,
          type: BlockType.EquationBlock,
          title: 'Block equation',
          icon: <Functions />,
          group: SlashCommandGroup.ADVANCED,
        },
      ].filter((option) => {
        if (!searchText) return true;
        const match = (text: string) => {
          return text.toLowerCase().includes(searchText.toLowerCase());
        };

        return match(option.title) || match(option.type);
      }),
    [searchText]
  );

  const optionsByGroup = useMemo(() => {
    return options.reduce((acc, option) => {
      if (!acc[option.group]) {
        acc[option.group] = [];
      }

      acc[option.group].push(option);
      return acc;
    }, {} as Record<SlashCommandGroup, typeof options>);
  }, [options]);

  const scrollIntoOption = useCallback((option: SlashCommandOption) => {
    if (!ref.current) return;
    const containerRect = ref.current.getBoundingClientRect();
    const optionElement = document.querySelector(`#slash-item-${option.key}`);

    if (!optionElement) return;
    const itemRect = optionElement?.getBoundingClientRect();

    if (!itemRect) return;

    if (itemRect.top < containerRect.top || itemRect.bottom > containerRect.bottom) {
      optionElement.scrollIntoView({ behavior: 'smooth' });
    }
  }, []);

  const selectOptionByArrow = useCallback(
    ({ isUp = false, isDown = false }: { isUp?: boolean; isDown?: boolean }) => {
      if (!isUp && !isDown) return;
      const optionsKeys = options.map((option) => String(option.key));
      const nextKey = selectOptionByUpDown(isUp, String(hoverOption?.key), optionsKeys);
      const nextOption = options.find((option) => String(option.key) === nextKey);

      if (!nextOption) return;

      scrollIntoOption(nextOption);
      dispatch(
        slashCommandActions.setHoverOption({
          option: nextOption,
          docId,
        })
      );
    },
    [dispatch, docId, hoverOption?.key, options, scrollIntoOption]
  );

  useEffect(() => {
    const handleKeyDownCapture = (e: KeyboardEvent) => {
      const isUp = e.key === Keyboard.keys.UP;
      const isDown = e.key === Keyboard.keys.DOWN;
      const isEnter = e.key === Keyboard.keys.ENTER;

      // if any arrow key is pressed, prevent default behavior and stop propagation
      if (isUp || isDown || isEnter) {
        e.stopPropagation();
        e.preventDefault();
        if (isEnter) {
          if (hoverOption) {
            handleInsert(hoverOption.type, hoverOption.data);
          }

          return;
        }

        selectOptionByArrow({
          isUp,
          isDown,
        });
      }
    };

    // intercept keydown event in capture phase before it reaches the editor
    container.addEventListener('keydown', handleKeyDownCapture, true);
    return () => {
      container.removeEventListener('keydown', handleKeyDownCapture, true);
    };
  }, [container, handleInsert, hoverOption, selectOptionByArrow]);

  const onHoverOption = useCallback(
    (option: SlashCommandOption) => {
      dispatch(
        slashCommandActions.setHoverOption({
          option: {
            key: option.key,
            type: option.type,
            data: option.data,
          },
          docId,
        })
      );
    },
    [dispatch, docId]
  );

  return (
    <div
      onMouseDown={(e) => {
        e.preventDefault();
        e.stopPropagation();
      }}
      className={'flex h-[100%] max-h-[40vh] w-[324px] min-w-[180px] max-w-[calc(100vw-32px)] flex-col p-1'}
    >
      <div ref={ref} className={'min-h-0 flex-1 overflow-y-auto overflow-x-hidden'}>
        {Object.entries(optionsByGroup).map(([group, options]) => (
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
                    onHover={() => {
                      onHoverOption(option);
                    }}
                    isHovered={hoverOption?.key === option.key}
                    onClick={() => {
                      handleInsert(option.type, option.data);
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
