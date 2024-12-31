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

function TitleEditable({
  viewId,
  name,
  onUpdateName,
  onEnter,
}: {
  viewId: string;
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
    const contentBox = contentRef.current;

    if (!contentBox) return;

    const textbox = document.getElementById(`editor-${viewId}`) as HTMLElement;

    textbox?.focus();
  };

  useEffect(() => {
    const contentBox = contentRef.current;

    if (!contentBox) return;
    contentBox.focus();
    if (contentBox.textContent !== '') {
      const range = document.createRange();
      const sel = window.getSelection();

      range.setStart(contentBox.childNodes[0], contentBox.textContent?.length || 0);
      range.collapse(true);
      sel?.removeAllRanges();
      sel?.addRange(range);
    }
  }, []);

  return (
    <div
      ref={contentRef}
      suppressContentEditableWarning={true}
      id={`editor-title-${viewId}`}
      style={{
        wordBreak: 'break-word',
      }}
      className={'relative flex-1 custom-caret break-words whitespace-pre-wrap cursor-text focus:outline-none empty:before:content-[attr(data-placeholder)] empty:before:text-text-placeholder'}
      data-placeholder={t('menuAppHeader.defaultNewPageName')}
      contentEditable={true}
      aria-readonly={false}
      autoFocus={true}
      onInput={() => {
        if (!contentRef.current) return;
        debounceUpdateName(contentRef.current.textContent || '');
        if (contentRef.current.innerHTML === '<br>') {
          contentRef.current.innerHTML = '';
        }
      }}
      onBlur={() => {
        if (!contentRef.current) return;
        onUpdateName(contentRef.current.textContent || '');
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