import React, { FormEventHandler, memo, useCallback, useRef } from 'react';
import { TextareaAutosize } from '@mui/material';
import { useTranslation } from 'react-i18next';

function ViewTitleInput({ value, onChange }: { value: string; onChange?: (value: string) => void }) {
  const { t } = useTranslation();
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const onTitleChange: FormEventHandler<HTMLTextAreaElement> = useCallback(
    (e) => {
      const value = e.currentTarget.value;

      onChange?.(value);
    },
    [onChange]
  );

  return (
    <TextareaAutosize
      ref={textareaRef}
      placeholder={t('document.title.placeholder')}
      autoCorrect='off'
      autoFocus
      value={value}
      onInput={onTitleChange}
      className={`min-h-[40px] resize-none text-5xl font-bold leading-[50px] caret-text-title`}
    />
  );
}

export default memo(ViewTitleInput);
