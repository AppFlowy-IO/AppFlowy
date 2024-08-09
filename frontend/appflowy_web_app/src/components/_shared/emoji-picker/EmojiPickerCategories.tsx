import { EMOJI_SIZE, PER_ROW_EMOJI_COUNT } from '@/components/_shared/emoji-picker/const';
import { AFScroller } from '@/components/_shared/scroller';
import { getDistanceEdge, inView } from '@/utils/position';
import { Tooltip } from '@mui/material';
import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import AutoSizer from 'react-virtualized-auto-sizer';
import { FixedSizeList } from 'react-window';
import { EmojiCategory, getRowsWithCategories } from './EmojiPicker.hooks';

function EmojiPickerCategories({
  emojiCategories,
  onEmojiSelect,
  onEscape,
  defaultEmoji,
}: {
  emojiCategories: EmojiCategory[];
  onEmojiSelect: (emoji: string) => void;
  onEscape?: () => void;
  defaultEmoji?: string;
}) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const { t } = useTranslation();
  const [selectCell, setSelectCell] = React.useState({
    row: 1,
    column: 0,
  });
  const rows = useMemo(() => {
    return getRowsWithCategories(emojiCategories, PER_ROW_EMOJI_COUNT);
  }, [emojiCategories]);
  const mouseY = useRef<number | null>(null);
  const mouseX = useRef<number | null>(null);

  const ref = React.useRef<HTMLDivElement>(null);

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

  useEffect(() => {
    scrollRef.current?.scrollTo({
      top: 0,
    });

    setSelectCell({
      row: 1,
      column: 0,
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [rows]);

  const renderRow = useCallback(
    ({ index, style }: { index: number; style: React.CSSProperties }) => {
      const item = rows[index];
      const tagName = getCategoryName(item.id);
      const isFlags = item.category === 'flags';

      return (
        <div style={style} data-index={index}>
          {item.type === 'category' ? (
            <div className={'pt-2 text-base font-medium text-text-caption'}>{tagName}</div>
          ) : null}
          <div className={'flex'}>
            {item.emojis?.map((emoji, columnIndex) => {
              const isSelected = selectCell.row === index && selectCell.column === columnIndex;

              const isDefaultEmoji = defaultEmoji === emoji.native;
              const classList = [
                'flex cursor-pointer items-center justify-center rounded text-[20px] hover:bg-fill-list-hover',
              ];

              if (isSelected) {
                classList.push('bg-fill-list-hover');
              } else {
                classList.push('hover:bg-transparent');
              }

              if (isDefaultEmoji) {
                classList.push('bg-fill-list-active');
              }

              if (isFlags) {
                classList.push('icon');
              }

              return (
                <Tooltip key={emoji.id} title={emoji.name} placement={'top'} enterDelay={500} disableInteractive={true}>
                  <div
                    data-key={emoji.id}
                    style={{
                      width: EMOJI_SIZE,
                      height: EMOJI_SIZE,
                    }}
                    onClick={() => {
                      onEmojiSelect(emoji.native);
                    }}
                    onMouseMove={(e) => {
                      mouseY.current = e.clientY;
                      mouseX.current = e.clientX;
                    }}
                    onMouseEnter={(e) => {
                      if (mouseY.current === null || mouseY.current !== e.clientY || mouseX.current !== e.clientX) {
                        setSelectCell({
                          row: index,
                          column: columnIndex,
                        });
                      }

                      mouseX.current = e.clientX;
                      mouseY.current = e.clientY;
                    }}
                    className={classList.join(' ')}
                  >
                    {emoji.native}
                  </div>
                </Tooltip>
              );
            })}
          </div>
        </div>
      );
    },
    [defaultEmoji, getCategoryName, onEmojiSelect, rows, selectCell.column, selectCell.row]
  );

  const getNewColumnIndex = useCallback(
    (rowIndex: number, columnIndex: number): number => {
      const row = rows[rowIndex];
      const length = row.emojis?.length;
      let newColumnIndex = columnIndex;

      if (length && length <= columnIndex) {
        newColumnIndex = length - 1 || 0;
      }

      return newColumnIndex;
    },
    [rows]
  );

  const findNextRow = useCallback(
    (rowIndex: number, columnIndex: number): { row: number; column: number } => {
      const rowLength = rows.length;
      let nextRowIndex = rowIndex + 1;

      if (nextRowIndex >= rowLength - 1) {
        nextRowIndex = rowLength - 1;
      } else if (rows[nextRowIndex].type === 'category') {
        nextRowIndex = findNextRow(nextRowIndex, columnIndex).row;
      }

      const newColumnIndex = getNewColumnIndex(nextRowIndex, columnIndex);

      return {
        row: nextRowIndex,
        column: newColumnIndex,
      };
    },
    [getNewColumnIndex, rows]
  );

  const findPrevRow = useCallback(
    (rowIndex: number, columnIndex: number): { row: number; column: number } => {
      let prevRowIndex = rowIndex - 1;

      if (prevRowIndex < 1) {
        prevRowIndex = 1;
      } else if (rows[prevRowIndex].type === 'category') {
        prevRowIndex = findPrevRow(prevRowIndex, columnIndex).row;
      }

      const newColumnIndex = getNewColumnIndex(prevRowIndex, columnIndex);

      return {
        row: prevRowIndex,
        column: newColumnIndex,
      };
    },
    [getNewColumnIndex, rows]
  );

  const findPrevCell = useCallback(
    (row: number, column: number): { row: number; column: number } => {
      const prevColumn = column - 1;

      if (prevColumn < 0) {
        const prevRow = findPrevRow(row, column).row;

        if (prevRow === row) return { row, column };
        const length = rows[prevRow].emojis?.length || 0;

        return {
          row: prevRow,
          column: length > 0 ? length - 1 : 0,
        };
      }

      return {
        row,
        column: prevColumn,
      };
    },
    [findPrevRow, rows]
  );

  const findNextCell = useCallback(
    (row: number, column: number): { row: number; column: number } => {
      const nextColumn = column + 1;

      const rowLength = rows[row].emojis?.length || 0;

      if (nextColumn >= rowLength) {
        const nextRow = findNextRow(row, column).row;

        if (nextRow === row) return { row, column };
        return {
          row: nextRow,
          column: 0,
        };
      }

      return {
        row,
        column: nextColumn,
      };
    },
    [findNextRow, rows]
  );

  useEffect(() => {
    if (!selectCell || !scrollRef.current) return;
    const emojiKey = rows[selectCell.row]?.emojis?.[selectCell.column]?.id;
    const emojiDom = document.querySelector(`[data-key="${emojiKey}"]`);

    if (emojiDom && !inView(emojiDom as HTMLElement, scrollRef.current as HTMLElement)) {
      const distance = getDistanceEdge(emojiDom as HTMLElement, scrollRef.current as HTMLElement);

      scrollRef.current?.scrollTo({
        top: scrollRef.current?.scrollTop + distance,
      });
    }
  }, [selectCell, rows]);

  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      e.stopPropagation();

      switch (e.key) {
        case 'Escape':
          e.preventDefault();
          onEscape?.();
          break;
        case 'ArrowUp': {
          e.preventDefault();

          setSelectCell(findPrevRow(selectCell.row, selectCell.column));

          break;
        }

        case 'ArrowDown': {
          e.preventDefault();

          setSelectCell(findNextRow(selectCell.row, selectCell.column));

          break;
        }

        case 'ArrowLeft': {
          e.preventDefault();

          const prevCell = findPrevCell(selectCell.row, selectCell.column);

          setSelectCell(prevCell);
          break;
        }

        case 'ArrowRight': {
          e.preventDefault();

          const nextCell = findNextCell(selectCell.row, selectCell.column);

          setSelectCell(nextCell);
          break;
        }

        case 'Enter': {
          e.preventDefault();
          const currentRow = rows[selectCell.row];
          const emoji = currentRow.emojis?.[selectCell.column];

          if (emoji) {
            onEmojiSelect(emoji.native);
          }

          break;
        }

        default:
          break;
      }
    },
    [
      findNextCell,
      findPrevCell,
      findPrevRow,
      findNextRow,
      onEmojiSelect,
      onEscape,
      rows,
      selectCell.column,
      selectCell.row,
    ]
  );

  useEffect(() => {
    const focusElement = document.querySelector('.emoji-picker .search-emoji-input') as HTMLInputElement;

    const parentElement = ref.current?.parentElement;

    focusElement?.addEventListener('keydown', handleKeyDown);
    parentElement?.addEventListener('keydown', handleKeyDown);
    return () => {
      focusElement?.removeEventListener('keydown', handleKeyDown);
      parentElement?.removeEventListener('keydown', handleKeyDown);
    };
  }, [handleKeyDown]);

  return (
    <div
      ref={ref}
      className={`mt-2 w-[${
        EMOJI_SIZE * PER_ROW_EMOJI_COUNT
      }px] flex-1 transform items-center justify-center overflow-y-auto overflow-x-hidden`}
    >
      <AutoSizer>
        {({ height, width }: { height: number; width: number }) => (
          <FixedSizeList
            overscanCount={10}
            height={height}
            width={width}
            outerRef={scrollRef}
            itemCount={rows.length}
            itemSize={EMOJI_SIZE}
            itemData={rows}
            outerElementType={AFScroller}
          >
            {renderRow}
          </FixedSizeList>
        )}
      </AutoSizer>
    </div>
  );
}

export default EmojiPickerCategories;
