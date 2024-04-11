import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { MenuItem, Typography } from '@mui/material';
import { scrollIntoView } from '$app/components/_shared/keyboard_navigation/utils';
import { useTranslation } from 'react-i18next';

/**
 * The option of the keyboard navigation
 * the options will be flattened
 * - key: the key of the option
 * - content: the content of the option
 * - children: the children of the option
 */
export interface KeyboardNavigationOption<T = string> {
  key: T;
  content?: React.ReactNode;
  children?: KeyboardNavigationOption<T>[];
  disabled?: boolean;
}

/**
 *  - scrollRef: the scrollable element
 *  - focusRef: the element to focus when the keyboard navigation is disabled
 *  - options: the options to navigate
 *  - onSelected: called when an option is selected(hovered)
 *  - onConfirm: called when an option is confirmed
 *  - onEscape: called when the escape key is pressed
 *  - onPressRight: called when the right arrow is pressed
 *  - onPressLeft: called when the left arrow key is pressed
 *  - disableFocus: disable the focus on the keyboard navigation
 *  - disableSelect: disable selecting an option when the options are initialized
 *  - onKeyDown: called when a key is pressed
 *  - defaultFocusedKey: the default focused key
 *  - onFocus: called when the keyboard navigation is focused
 *  - onBlur: called when the keyboard navigation is blurred
 */
export interface KeyboardNavigationProps<T> {
  scrollRef?: React.RefObject<HTMLDivElement>;
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
  itemClassName?: string;
  itemStyle?: React.CSSProperties;
  renderNoResult?: () => React.ReactNode;
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
  itemClassName,
  itemStyle,
  renderNoResult,
}: KeyboardNavigationProps<T>) {
  const { t } = useTranslation();
  const ref = useRef<HTMLDivElement>(null);
  const mouseY = useRef<number | null>(null);
  const defaultKeyRef = useRef<T | undefined>(defaultFocusedKey);
  // flatten the options
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

  // set the default focused key when the options are initialized
  useEffect(() => {
    if (defaultKeyRef.current) {
      setFocusedKey(defaultKeyRef.current);
      defaultKeyRef.current = undefined;
      return;
    }

    setFocusedKey(firstOptionKey);
  }, [firstOptionKey]);

  // call the onSelected callback when the focused key is changed
  useEffect(() => {
    if (focusedKey === undefined) return;
    onSelected?.(focusedKey);

    const scrollElement = scrollRef?.current;

    if (!scrollElement) return;

    const dom = ref.current?.querySelector(`[data-key="${focusedKey}"]`);

    if (!dom) return;
    // scroll the focused option into view
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
        // move the focus to the previous option
        case 'ArrowUp': {
          e.preventDefault();

          const prevKey = flattenOptions[prevIndex]?.key;

          setFocusedKey(prevKey);

          break;
        }

        // move the focus to the next option
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
        // confirm the focused option
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
      const hasChildren = option.children;

      const isFocused = focusedKey === option.key;

      return (
        <div className={'flex flex-col gap-1'} key={option.key as string}>
          {hasChildren ? (
            // render the group name
            option.content && <div className={'text-text-caption'}>{option.content}</div>
          ) : (
            // render the option
            <MenuItem
              disabled={option.disabled}
              data-key={option.key}
              // prevent the focused option is changed when the mouse is not moved but the mouse is entered when scrolling into view
              onMouseMove={(e) => {
                mouseY.current = e.clientY;
              }}
              onMouseEnter={(e) => {
                onFocus?.();
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
              style={itemStyle}
              className={`ml-0 flex w-full items-center justify-start rounded-none px-2 py-1 text-xs ${
                !isFocused ? 'hover:bg-transparent' : ''
              } ${itemClassName ?? ''}`}
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
    [itemClassName, focusedKey, onConfirm, onFocus, itemStyle]
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
        element = document.activeElement as HTMLElement;
      }

      element?.addEventListener('keydown', onKeyDown);
      return () => {
        element?.removeEventListener('keydown', onKeyDown);
      };
    }
  }, [disableFocus, onKeyDown, focusRef]);

  return (
    <div
      tabIndex={0}
      onFocus={(e) => {
        e.stopPropagation();

        onFocus?.();
      }}
      onBlur={(e) => {
        e.stopPropagation();

        const target = e.relatedTarget as HTMLElement;

        if (target?.closest('.keyboard-navigation')) {
          return;
        }

        onBlur?.();
      }}
      autoFocus={!disableFocus}
      className={'keyboard-navigation flex w-full flex-col gap-1 outline-none'}
      ref={ref}
    >
      {options.length > 0 ? (
        options.map(renderOption)
      ) : renderNoResult ? (
        renderNoResult()
      ) : (
        <Typography variant='body1' className={'p-3 text-xs text-text-caption'}>
          {t('findAndReplace.noResult')}
        </Typography>
      )}
    </div>
  );
}

export default KeyboardNavigation;
