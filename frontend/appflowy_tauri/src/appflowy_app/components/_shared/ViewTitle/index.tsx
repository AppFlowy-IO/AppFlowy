import React, { FormEventHandler, useCallback, useRef, useState } from 'react';
import ViewBanner from '$app/components/_shared/ViewTitle/ViewBanner';
import { Page, PageIcon } from '$app_reducers/pages/slice';
import { ViewIconTypePB } from '@/services/backend';
import { TextareaAutosize } from '@mui/material';
import { useTranslation } from 'react-i18next';

interface Props {
  view: Page;
  onTitleChange: (title: string) => void;
  onUpdateIcon: (icon: PageIcon) => void;
}

function ViewTitle({ view, onTitleChange: onTitleChangeProp, onUpdateIcon: onUpdateIconProp }: Props) {
  const { t } = useTranslation();
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const [hover, setHover] = useState(false);
  const [icon, setIcon] = useState<PageIcon | undefined>(view.icon);

  const defaultValue = useRef(view.name);
  const onTitleChange: FormEventHandler<HTMLTextAreaElement> = (e) => {
    const value = e.currentTarget.value;

    onTitleChangeProp(value);
  };

  const onUpdateIcon = useCallback(
    (icon: string) => {
      const newIcon = {
        value: icon,
        ty: ViewIconTypePB.Emoji,
      };

      setIcon(newIcon);
      onUpdateIconProp(newIcon);
    },
    [onUpdateIconProp]
  );

  return (
    <div className={'flex flex-col'} onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}>
      <ViewBanner icon={icon} hover={hover} onUpdateIcon={onUpdateIcon} />
      <div className='relative'>
        <TextareaAutosize
          ref={textareaRef}
          placeholder={t('document.title.placeholder')}
          className='min-h-[40px] resize-none text-4xl font-bold caret-text-title'
          autoCorrect='off'
          defaultValue={defaultValue.current}
          onInput={onTitleChange}
        />
      </div>
    </div>
  );
}

export default ViewTitle;
