import React from 'react';
import { useTranslation } from 'react-i18next';

export function Title({ icon, name }: { icon?: string; name?: string }) {
  const { t } = useTranslation();

  return (
    <div className={'flex w-full flex-col py-4'}>
      <div className={'flex w-full items-center px-16 max-md:px-4'}>
        <div className={'flex items-center gap-2 text-3xl'}>
          <div>{icon}</div>
          <div className={'font-bold'}>{name || t('document.title.placeholder')}</div>
        </div>
      </div>
    </div>
  );
}

export default Title;
