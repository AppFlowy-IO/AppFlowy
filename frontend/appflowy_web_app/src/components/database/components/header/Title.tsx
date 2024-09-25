import React from 'react';
import { useTranslation } from 'react-i18next';

export function Title ({ icon, name }: { icon?: string; name?: string }) {
  const { t } = useTranslation();

  return (
    <div className={'flex w-full flex-col py-4 mt-10 px-6'}>
      <div className={'flex w-full items-center'}>
        <div className={'flex gap-2 text-3xl'}>
          {icon ? <div>{icon}</div> : null}
          <div
            className={`font-bold ${!name ? 'text-text-placeholder' : 'text-text-title'}`}
          >{name || t('document.title.placeholder')}</div>
        </div>
      </div>
    </div>
  );
}

export default Title;
