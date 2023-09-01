import React, { useCallback, useMemo } from 'react';
import {
  EMOJI_SIZE,
  EmojiCategory,
  getRowsWithCategories,
  PER_ROW_EMOJI_COUNT,
  useVirtualizedCategories,
} from '$app/components/_shared/EmojiPicker/EmojiPicker.hooks';
import { useTranslation } from 'react-i18next';
import { IconButton } from '@mui/material';

function EmojiPickerCategories({
  emojiCategories,
  onEmojiSelect,
}: {
  emojiCategories: EmojiCategory[];
  onEmojiSelect: (emoji: string) => void;
}) {
  const { t } = useTranslation();
  const rows = useMemo(() => {
    return getRowsWithCategories(emojiCategories, PER_ROW_EMOJI_COUNT);
  }, [emojiCategories]);

  const { ref, virtualize } = useVirtualizedCategories({
    count: rows.length,
  });
  const virtualItems = virtualize.getVirtualItems();

  const getCategoryName = useCallback(
    (id: string) => {
      const i18nName: Record<string, string> = {
        frequent: t('emoji.categories.frequentlyUsed'),
        people: t('emoji.categories.people'),
        nature: t('emoji.categories.nature'),
        foods: t('emoji.categories.food'),
        activity: t('emoji.categories.activities'),
        places: t('emoji.categories.places'),
        objects: t('emoji.categories.objects'),
        symbols: t('emoji.categories.symbols'),
        flags: t('emoji.categories.flags'),
      };

      return i18nName[id];
    },
    [t]
  );

  return (
    <div
      ref={ref}
      className={`mt-2 w-[${
        EMOJI_SIZE * PER_ROW_EMOJI_COUNT
      }px] flex-1 items-center justify-center overflow-y-auto overflow-x-hidden`}
    >
      <div
        style={{
          height: virtualize.getTotalSize(),
          position: 'relative',
        }}
        className={'mx-1'}
      >
        {virtualItems.length ? (
          <div
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              transform: `translateY(${virtualItems[0].start || 0}px)`,
            }}
          >
            {virtualItems.map(({ index }) => {
              const item = rows[index];

              return (
                <div data-index={index} ref={virtualize.measureElement} key={item.id} className={'flex flex-col'}>
                  {item.type === 'category' ? (
                    <div className={'p-2 text-sm font-medium text-text-caption'}>{getCategoryName(item.id)}</div>
                  ) : null}
                  <div className={'flex'}>
                    {item.emojis?.map((emoji) => {
                      return (
                        <div
                          key={emoji.id}
                          style={{
                            width: EMOJI_SIZE,
                            height: EMOJI_SIZE,
                          }}
                          className={`flex items-center justify-center`}
                        >
                          <IconButton
                            size={'small'}
                            onClick={() => {
                              onEmojiSelect(emoji.native);
                            }}
                          >
                            {emoji.native}
                          </IconButton>
                        </div>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>
        ) : null}
      </div>
    </div>
  );
}

export default EmojiPickerCategories;
