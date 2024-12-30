import { TemplateIcon } from '@/application/template.type';
import { CategoryIcon } from '@/components/as-template/icons';
import { IconButton, InputLabel } from '@mui/material';
import React, { forwardRef } from 'react';
import { useTranslation } from 'react-i18next';

const options = Object.values(TemplateIcon);

const IconPicker = forwardRef<HTMLDivElement, {
  value: string;
  onChange: (value: string) => void;
}>(({ value, onChange }, ref) => {
  const { t } = useTranslation();

  return (
    <div ref={ref} className={'flex flex-col gap-2'}>
      <InputLabel>{t('template.category.icons')}</InputLabel>
      <div className={'flex gap-2 flex-wrap'}>
        {options.map((icon) => {
          return (
            <IconButton
              className={`flex items-center justify-center p-2 w-10 h-10`}
              style={{
                backgroundColor: value === icon ? 'var(--fill-list-hover)' : undefined,
              }}
              key={icon}
              onClick={() => onChange(icon)}
            >
              <CategoryIcon icon={icon} />
            </IconButton>
          );
        })}
      </div>
    </div>
  );
});

export default IconPicker;