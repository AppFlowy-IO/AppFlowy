import React, { FormEventHandler, memo, useCallback, useRef } from 'react';
import { TextareaAutosize } from '@mui/material';
import { useTranslation } from 'react-i18next';

function ViewTitleInput({
  value,
  onChange,
  onSplitTitle,
}: {
  value: string;
  onChange: (value: string) => void;
  onSplitTitle?: (splitText: string) => void;
}) {
  const { t } = useTranslation();
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const onTitleChange: FormEventHandler<HTMLTextAreaElement> = (e) => {
    const value = e.currentTarget.value;

    onChange(value);
  };

  const handleBreakLine = useCallback(() => {
    if (!onSplitTitle) return;
    const selectionStart = textareaRef.current?.selectionStart;

    if (value) {
      const newValue = value.slice(0, selectionStart);

      onChange(newValue);
      onSplitTitle(value.slice(selectionStart));
    }
  }, [onSplitTitle, onChange, value]);

  return (
    <TextareaAutosize
      ref={textareaRef}
      placeholder={t('document.title.placeholder')}
      className='min-h-[40px] resize-none text-4xl font-bold leading-[50px] caret-text-title'
      autoCorrect='off'
      autoFocus
      value={value}
      onInput={onTitleChange}
      onKeyDown={(e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          e.stopPropagation();
          handleBreakLine();
        }
      }}
    />
  );
}

export default memo(ViewTitleInput);
