import React from 'react';
import { useTranslation } from 'react-i18next';
import { colors } from './config';

function ChangeColors({ cover, onChange }: { cover: string; onChange: (color: string) => void }) {
  const { t } = useTranslation();

  return (
    <div className={'flex flex-col'}>
      <div className={'p-2 pb-4 text-text-caption'}>{t('document.plugins.cover.colors')}</div>
      <div className={'flex flex-wrap'}>
        {colors.map((color) => (
          <div
            onClick={() => onChange(color)}
            key={color}
            style={{ backgroundColor: color }}
            className={`m-1 flex h-[20px] w-[20px] cursor-pointer items-center justify-center rounded-[50%]`}
          >
            {cover === color && (
              <div
                style={{
                  borderColor: '#fff',
                  backgroundColor: color,
                }}
                className={'h-[16px] w-[calc(16px)] rounded-[50%] border-[2px] border-solid'}
              />
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export default ChangeColors;
