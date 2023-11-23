import { useAppDispatch } from '$app/stores/store';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { slashCommandActions } from '$app_reducers/document/slice';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useSubscribeSlashState } from '$app/components/document/_shared/SubscribeSlash.hooks';
import { useSubscribePanelSearchText } from '$app/components/document/_shared/usePanelSearchText';
import { BlockData, BlockType, SlashCommandOption, SlashCommandOptionKey } from '$app/interfaces/document';
import { selectOptionByUpDown } from '$app/utils/document/menu';
import { Keyboard } from '$app/constants/document/keyboard';

export function useKeyboardShortcut({
  container,
  options,
  handleInsert,
  hoverOption,
}: {
  container: HTMLElement;
  options: SlashCommandOption[];
  handleInsert: (type: BlockType, data?: BlockData) => Promise<void>;
  hoverOption?: SlashCommandOption;
}) {
  const ref = useRef<HTMLDivElement | null>(null);
  const dispatch = useAppDispatch();
  const { docId } = useSubscribeDocument();
  const scrollIntoOption = useCallback(
    (option: SlashCommandOption) => {
      if (!ref.current) return;
      const containerRect = ref.current.getBoundingClientRect();
      const optionElement = document.querySelector(`#slash-item-${option.key}`);

      if (!optionElement) return;
      const itemRect = optionElement?.getBoundingClientRect();

      if (!itemRect) return;

      if (itemRect.top < containerRect.top || itemRect.bottom > containerRect.bottom) {
        optionElement.scrollIntoView({ behavior: 'smooth' });
      }
    },
    [ref]
  );

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
            void handleInsert(hoverOption.type, hoverOption.data);
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

  return {
    ref,
  };
}

export function useBlockSlash() {
  const dispatch = useAppDispatch();
  const { docId } = useSubscribeDocument();
  const { blockId, visible, slashText, hoverOption } = useSubscribeSlash();
  const [anchorPosition, setAnchorPosition] = useState<{
    top: number;
    left: number;
  }>();
  const [subMenuAnchorPosition, setSubMenuAnchorPosition] = useState<{
    top: number;
    left: number;
  }>();

  useEffect(() => {
    if (blockId && visible) {
      const blockEl = document.querySelector(`[data-block-id="${blockId}"]`) as HTMLElement;
      const el = blockEl.querySelector(`[role="textbox"]`) as HTMLElement;

      if (el) {
        const rect = el.getBoundingClientRect();

        setAnchorPosition({
          top: rect.top + rect.height,
          left: rect.left,
        });
        return;
      }
    }

    setAnchorPosition(undefined);
  }, [blockId, visible]);

  const searchText = useMemo(() => {
    if (!slashText) return '';
    if (slashText[0] !== '/') return slashText;

    return slashText.slice(1, slashText.length);
  }, [slashText]);

  const onClose = useCallback(() => {
    setSubMenuAnchorPosition(undefined);
    dispatch(slashCommandActions.closeSlashCommand(docId));
  }, [dispatch, docId]);

  const open = Boolean(anchorPosition);

  const onHoverOption = useCallback(
    (option: SlashCommandOption, target: HTMLElement) => {
      setSubMenuAnchorPosition(undefined);
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

      if (option.key === SlashCommandOptionKey.GRID_REFERENCE) {
        const rect = target.getBoundingClientRect();

        setSubMenuAnchorPosition({
          top: rect.top,
          left: rect.right,
        });
      }
    },
    [dispatch, docId]
  );

  const onCloseSubMenu = useCallback(() => {
    setSubMenuAnchorPosition(undefined);
  }, []);

  return {
    open,
    anchorPosition,
    onClose,
    blockId,
    searchText,
    hoverOption,
    onHoverOption,
    onCloseSubMenu,
    subMenuAnchorPosition,
  };
}

export function useSubscribeSlash() {
  const slashCommandState = useSubscribeSlashState();
  const visible = slashCommandState.isSlashCommand;
  const blockId = slashCommandState.blockId;
  const { searchText } = useSubscribePanelSearchText({ blockId: blockId || '', open: visible });

  return {
    visible,
    blockId,
    slashText: searchText,
    hoverOption: slashCommandState.hoverOption,
  };
}
