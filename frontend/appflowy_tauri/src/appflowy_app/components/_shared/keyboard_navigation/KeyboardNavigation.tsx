import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { MenuItem, Typography } from '@mui/material';
import { scrollIntoView } from '$app/components/_shared/keyboard_navigation/utils';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { useTranslation } from 'react-i18next';

export interface KeyboardNavigationOption<T = string> {
  key: T;
  content?: React.ReactNode;
  children?: KeyboardNavigationOption<T>[];
  disabled?: boolean;
}

export interface KeyboardNavigationProps<T> {
  scrollRef: React.RefObject<HTMLDivElement>;
  focusRef?: React.RefObject<HTMLElement>;
  options: KeyboardNavigationOption<T>[];
  onSelected?: (optionKey: T) => void;
  onConfirm?: (optionKey: T) => void;
  onEscape?: () => void;
  onPressRight?: (optionKey: T) => void;
  onPressLeft?: (optionKey: T) => void;
  disableFocus?: boolean;
  disableSelect?: boolean;
  onKeyDown?: (e: KeyboardEvent) => void;
  defaultFocusedKey?: T;
  onFocus?: () => void;
  onBlur?: () => void;
}

function KeyboardNavigation<T>({
  defaultFocusedKey,
  onPressRight,
  onPressLeft,
  onEscape,
  onConfirm,
  scrollRef,
  options,
  onSelected,
  focusRef,
  disableFocus = false,
  onKeyDown: onPropsKeyDown,
  disableSelect = false,
  onBlur,
  onFocus,
}: KeyboardNavigationProps<T>) {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const ref = useRef<HTMLDivElement>(null);
  const mouseY = useRef<number | null>(null);
  const defaultKeyRef = useRef<T | undefined>(defaultFocusedKey);
  const flattenOptions = useMemo(() => {
    return options.flatMap((group) => {
      if (group.children) {
        return group.children;
      }

      return [group];
    });
  }, [options]);

  const [focusedKey, setFocusedKey] = useState<T>();

  const firstOptionKey = useMemo(() => {
    if (disableSelect) return;
    const firstOption = flattenOptions.find((option) => !option.disabled);

    return firstOption?.key;
  }, [flattenOptions, disableSelect]);

  useEffect(() => {
    if (defaultKeyRef.current) {
      setFocusedKey(defaultKeyRef.current);
      defaultKeyRef.current = undefined;
      return;
    }

    setFocusedKey(firstOptionKey);
  }, [firstOptionKey]);

  useEffect(() => {
    if (focusedKey === undefined) return;
    onSelected?.(focusedKey);

    const scrollElement = scrollRef.current;

    if (!scrollElement) return;

    const dom = ref.current?.querySelector(`[data-key="${focusedKey}"]`);

    if (!dom) return;
    requestAnimationFrame(() => {
      scrollIntoView(dom as HTMLDivElement, scrollElement);
    });
  }, [focusedKey, onSelected, scrollRef]);

  const onKeyDown = useCallback(
    (e: KeyboardEvent) => {
      onPropsKeyDown?.(e);
      e.stopPropagation();
      const key = e.key;

      if (key === 'Tab') {
        e.preventDefault();
        return;
      }

      if (key === 'Escape') {
        e.preventDefault();
        onEscape?.();
        return;
      }

      if (focusedKey === undefined) return;
      const focusedIndex = flattenOptions.findIndex((option) => option?.key === focusedKey);
      const nextIndex = (focusedIndex + 1) % flattenOptions.length;
      const prevIndex = (focusedIndex - 1 + flattenOptions.length) % flattenOptions.length;

      switch (key) {
        case 'ArrowUp': {
          e.preventDefault();

          const prevKey = flattenOptions[prevIndex]?.key;

          setFocusedKey(prevKey);

          break;
        }

        case 'ArrowDown': {
          e.preventDefault();
          const nextKey = flattenOptions[nextIndex]?.key;

          setFocusedKey(nextKey);
          break;
        }

        case 'ArrowRight':
          if (onPressRight) {
            e.preventDefault();
            onPressRight(focusedKey);
          }

          break;
        case 'ArrowLeft':
          if (onPressLeft) {
            e.preventDefault();
            onPressLeft(focusedKey);
          }

          break;
        case 'Enter': {
          e.preventDefault();
          const disabled = flattenOptions[focusedIndex]?.disabled;

          if (!disabled) {
            onConfirm?.(focusedKey);
          }

          break;
        }

        default:
          break;
      }
    },
    [flattenOptions, focusedKey, onConfirm, onEscape, onPressLeft, onPressRight, onPropsKeyDown]
  );

  const renderOption = useCallback(
    (option: KeyboardNavigationOption<T>, index: number) => {
      const hasChildren = option.children && option.children.length > 0;

      const isFocused = focusedKey === option.key;

      return (
        <div className={'flex flex-col gap-1'} key={option.key as string}>
          {hasChildren ? (
            option.content && <div className={'text-text-caption'}>{option.content}</div>
          ) : (
            <MenuItem
              disabled={option.disabled}
              data-key={option.key}
              onMouseMove={(e) => {
                mouseY.current = e.clientY;
              }}
              onMouseEnter={(e) => {
                if (mouseY.current === null || mouseY.current !== e.clientY) {
                  setFocusedKey(option.key);
                }

                mouseY.current = e.clientY;
              }}
              onClick={() => {
                setFocusedKey(option.key);
                if (!option.disabled) {
                  onConfirm?.(option.key);
                }
              }}
              selected={isFocused}
              className={`ml-0 flex w-full items-center justify-start rounded-none px-2 py-1 text-xs ${
                !isFocused ? 'hover:bg-transparent' : ''
              }`}
            >
              {option.content}
            </MenuItem>
          )}

          {option.children?.map((child, childIndex) => {
            return renderOption(child, index + childIndex);
          })}
        </div>
      );
    },
    [focusedKey, onConfirm]
  );

  useEffect(() => {
    const element = ref.current;

    if (!disableFocus && element) {
      element.focus();
      element.addEventListener('keydown', onKeyDown);

      return () => {
        element.removeEventListener('keydown', onKeyDown);
      };
    } else {
      let element: HTMLElement | null | undefined = focusRef?.current;

      if (!element) {
        element = ReactEditor.toDOMNode(editor, editor);
      }

      element.addEventListener('keydown', onKeyDown);
      return () => {
        element?.removeEventListener('keydown', onKeyDown);
      };
    }
  }, [disableFocus, editor, onKeyDown, focusRef]);

  return (
    <div
      tabIndex={0}
      onFocus={(e) => {
        e.stopPropagation();

        onFocus?.();
      }}
      onBlur={(e) => {
        e.stopPropagation();

        onBlur?.();
      }}
      autoFocus={!disableFocus}
      className={'flex w-full flex-col gap-1 outline-none'}
      ref={ref}
    >
      {options.length > 0 ? (
        options.map(renderOption)
      ) : (
        <Typography variant='body1' className={'p-3 text-text-caption'}>
          {t('findAndReplace.noResult')}
        </Typography>
      )}
    </div>
  );
}

export default KeyboardNavigation;
