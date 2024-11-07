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

function TitleEditable ({
  name,
  onUpdateName,
}: {
  name: string;
  onUpdateName: (name: string) => void;
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

  const focusdTextbox = () => {
    const textbox = document.querySelector('[role="textbox"]') as HTMLElement;

    textbox?.focus();
  };

  return (
    <div
      ref={contentRef}
      suppressContentEditableWarning={true}
      className={'relative flex-1 cursor-text focus:outline-none empty:before:content-[attr(data-placeholder)] empty:before:text-text-placeholder'}
      data-placeholder={t('menuAppHeader.defaultNewPageName')}
      contentEditable={true}
      aria-readonly={false}
      onBlur={() => {
        if (!contentRef.current) return;
        debounceUpdateName(contentRef.current.textContent || '');
      }}
      onKeyDown={(e) => {
        if (!contentRef.current) return;
        if (e.key === 'Enter' || e.key === 'Escape') {
          e.preventDefault();
          if (!contentRef.current) return;
          onUpdateName(contentRef.current.textContent || '');
          focusdTextbox();
        } else if (e.key === 'ArrowDown' || (e.key === 'ArrowRight' && isCursorAtEnd(contentRef.current))) {
          e.preventDefault();
          focusdTextbox();
        }
      }}
    />

  );
}

export default memo(TitleEditable);