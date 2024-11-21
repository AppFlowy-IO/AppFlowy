import { debounce } from 'lodash-es';
import React, { memo, useEffect, useMemo, useRef } from 'react';
import { useTranslation } from 'react-i18next';

const isCursorAtEnd = (el: HTMLDivElement) => {
  const selection = window.getSelection();

  if (!selection) return false;

  const range = selection.getRangeAt(0);
  const text = el.textContent || '';

  return range.startOffset === text.length;
};

const getCursorOffset = () => {
  const selection = window.getSelection();

  if (!selection) return 0;

  const range = selection.getRangeAt(0);

  return range.startOffset;
};

function TitleEditable ({
  name,
  onUpdateName,
  onEnter,
}: {
  name: string;
  onUpdateName: (name: string) => void;
  onEnter?: (text: string) => void;
}) {
  const { t } = useTranslation();
  const debounceUpdateName = useMemo(() => {
    return debounce(onUpdateName, 300);
  }, [onUpdateName]);
  const contentRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (contentRef.current) {
      contentRef.current.textContent = name;
    }
    // eslint-disable-next-line
  }, []);

  useEffect(() => {
    if (contentRef.current) {
      const activeElement = document.activeElement;

      if (activeElement === contentRef.current) {
        return;
      }

      contentRef.current.textContent = name;
    }
  }, [name]);

  const focusedTextbox = () => {
    const textbox = document.querySelector('[role="textbox"]') as HTMLElement;

    textbox?.focus();
  };

  return (
    <div
      ref={contentRef}
      suppressContentEditableWarning={true}
      id={'editor-title'}
      className={'relative flex-1 cursor-text focus:outline-none empty:before:content-[attr(data-placeholder)] empty:before:text-text-placeholder'}
      data-placeholder={t('menuAppHeader.defaultNewPageName')}
      contentEditable={true}
      aria-readonly={false}
      onInput={() => {
        if (!contentRef.current) return;
        debounceUpdateName(contentRef.current.textContent || '');
      }}
      onKeyDown={(e) => {
        if (!contentRef.current) return;
        if (e.key === 'Enter' || e.key === 'Escape') {
          e.preventDefault();
          if (e.key === 'Enter') {
            const offset = getCursorOffset();
            const beforeText = contentRef.current.textContent?.slice(0, offset) || '';
            const afterText = contentRef.current.textContent?.slice(offset) || '';

            contentRef.current.textContent = beforeText;
            onUpdateName(beforeText);
            onEnter?.(afterText);

            setTimeout(() => {
              focusedTextbox();
            }, 0);

          } else {
            onUpdateName(contentRef.current.textContent || '');
          }
        } else if (e.key === 'ArrowDown' || (e.key === 'ArrowRight' && isCursorAtEnd(contentRef.current))) {
          e.preventDefault();
          focusedTextbox();
        }
      }}
    />

  );
}

export default memo(TitleEditable);