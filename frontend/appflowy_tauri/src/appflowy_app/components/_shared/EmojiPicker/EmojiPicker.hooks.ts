import { useCallback, useEffect, useRef, useState } from 'react';
import emojiData, { EmojiMartData } from '@emoji-mart/data';
import { PopoverProps } from '@mui/material/Popover';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import { useVirtualizer } from '@tanstack/react-virtual';
import { chunkArray } from '$app/utils/tool';

export interface EmojiCategory {
  id: string;
  emojis: Emoji[];
}

interface Emoji {
  id: string;
  name: string;
  native: string;
}
export function useLoadEmojiData({ skin }: { skin: number }) {
  const [searchValue, setSearchValue] = useState('');
  const [emojiCategories, setEmojiCategories] = useState<EmojiCategory[]>([]);

  useEffect(() => {
    const { emojis, categories } = emojiData as EmojiMartData;

    const emojiCategories = categories
      .map((category) => {
        const { id, emojis: categoryEmojis } = category;

        return {
          id,
          emojis: categoryEmojis
            .filter((emojiId) => {
              const emoji = emojis[emojiId];

              if (!searchValue) return true;
              return filterSearchValue(emoji, searchValue);
            })
            .map((emojiId) => {
              const emoji = emojis[emojiId];
              const { id, name, skins } = emoji;

              return {
                id,
                name,
                native: skins[skin] ? skins[skin].native : skins[0].native,
              };
            }),
        };
      })
      .filter((category) => category.emojis.length > 0);

    setEmojiCategories(emojiCategories);
  }, [skin, searchValue]);

  return {
    emojiCategories,
    skin,
    setSearchValue,
    searchValue,
  };
}

export function useSelectSkinPopoverProps(): PopoverProps & {
  onOpen: (event: React.MouseEvent<HTMLButtonElement>) => void;
  onClose: () => void;
} {
  const [anchorEl, setAnchorEl] = useState<HTMLButtonElement | undefined>(undefined);
  const onOpen = useCallback((event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  }, []);
  const onClose = useCallback(() => {
    setAnchorEl(undefined);
  }, []);
  const open = Boolean(anchorEl);
  const anchorOrigin = { vertical: 'bottom', horizontal: 'center' } as PopoverOrigin;
  const transformOrigin = { vertical: 'top', horizontal: 'center' } as PopoverOrigin;

  return {
    anchorEl,
    onOpen,
    onClose,
    open,
    anchorOrigin,
    transformOrigin,
  };
}

function filterSearchValue(emoji: emojiData.Emoji, searchValue: string) {
  const { name, keywords } = emoji;
  const searchValueLowerCase = searchValue.toLowerCase();

  return (
    name.toLowerCase().includes(searchValueLowerCase) ||
    (keywords && keywords.some((keyword) => keyword.toLowerCase().includes(searchValueLowerCase)))
  );
}

export function getRowsWithCategories(emojiCategories: EmojiCategory[], rowSize: number) {
  const rows: {
    id: string;
    type: 'category' | 'emojis';
    emojis?: Emoji[];
  }[] = [];

  emojiCategories.forEach((category) => {
    rows.push({
      id: category.id,
      type: 'category',
    });
    chunkArray(category.emojis, rowSize).forEach((chunk, index) => {
      rows.push({
        type: 'emojis',
        emojis: chunk,
        id: `${category.id}-${index}`,
      });
    });
  });
  return rows;
}

export function useVirtualizedCategories({ count }: { count: number }) {
  const ref = useRef<HTMLDivElement>(null);
  const virtualize = useVirtualizer({
    count,
    getScrollElement: () => ref.current,
    estimateSize: () => {
      return 60;
    },
    overscan: 3,
  });

  return { virtualize, ref };
}
