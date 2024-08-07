import { loadEmojiData } from '@/utils/emoji';
import { EmojiMartData } from '@emoji-mart/data';
import { PopoverProps } from '@mui/material/Popover';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import chunk from 'lodash-es/chunk';
import React, { useCallback, useEffect, useState } from 'react';

export interface EmojiCategory {
  id: string;
  emojis: Emoji[];
}

interface Emoji {
  id: string;
  name: string;
  native: string;
}

export function useLoadEmojiData({ onEmojiSelect }: { onEmojiSelect: (emoji: string) => void }) {
  const [searchValue, setSearchValue] = useState('');
  const [emojiCategories, setEmojiCategories] = useState<EmojiCategory[]>([]);
  const [skin, setSkin] = useState<number>(() => {
    return Number(localStorage.getItem('emoji-mart.skin')) || 0;
  });

  const onSkinChange = useCallback((val: number) => {
    setSkin(val);
    localStorage.setItem('emoji-mart.skin', String(val));
  }, []);

  const searchEmojiData = useCallback(
    async (searchVal?: string) => {
      const emojiData = await loadEmojiData();

      const { emojis, categories } = emojiData as EmojiMartData;

      const filteredCategories = categories
        .map((category) => {
          const { id, emojis: categoryEmojis } = category;

          return {
            id,
            emojis: categoryEmojis
              .filter((emojiId) => {
                const emoji = emojis[emojiId];

                if (!searchVal) return true;
                return filterSearchValue(emoji, searchVal);
              })
              .map((emojiId) => {
                const emoji = emojis[emojiId];
                const { name, skins } = emoji;

                return {
                  id: emojiId,
                  name,
                  native: skins[skin] ? skins[skin].native : skins[0].native,
                };
              }),
          };
        })
        .filter((category) => category.emojis.length > 0);

      setEmojiCategories(filteredCategories);
    },
    [skin]
  );

  useEffect(() => {
    void (async () => {
      await searchEmojiData();
    })();
  }, [searchEmojiData]);

  useEffect(() => {
    void searchEmojiData(searchValue);
  }, [searchEmojiData, searchValue]);

  const onSelect = useCallback(
    async (native: string) => {
      onEmojiSelect(native);
    },
    [onEmojiSelect]
  );

  return {
    emojiCategories,
    setSearchValue,
    searchValue,
    onSelect,
    onSkinChange,
    skin,
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

function filterSearchValue(
  emoji: {
    name: string;
    keywords?: string[];
  },
  searchValue: string
) {
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
    category?: string;
  }[] = [];

  emojiCategories.forEach((category) => {
    rows.push({
      id: category.id,
      type: 'category',
    });
    chunk(category.emojis, rowSize).forEach((chunk, index) => {
      rows.push({
        category: category.id,
        type: 'emojis',
        emojis: chunk,
        id: `${category.id}-${index}`,
      });
    });
  });
  return rows;
}
