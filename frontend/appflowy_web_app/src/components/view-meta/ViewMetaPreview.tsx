import BuiltInImage1 from '@/assets/cover/m_cover_image_1.png';
import BuiltInImage2 from '@/assets/cover/m_cover_image_2.png';
import BuiltInImage3 from '@/assets/cover/m_cover_image_3.png';
import BuiltInImage4 from '@/assets/cover/m_cover_image_4.png';
import BuiltInImage5 from '@/assets/cover/m_cover_image_5.png';
import BuiltInImage6 from '@/assets/cover/m_cover_image_6.png';
import ViewCover from '@/components/view-meta/ViewCover';
import { isFlagEmoji } from '@/utils/emoji';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { CoverType, ViewLayout, ViewMetaIcon } from '@/application/types';

export interface ViewMetaCover {
  type: CoverType;
  value: string;
}

export interface ViewMetaProps {
  icon?: ViewMetaIcon;
  cover?: ViewMetaCover;
  name?: string;
  viewId?: string;
  layout?: ViewLayout;
  visibleViewIds?: string[];
}

export function ViewMetaPreview ({ icon, cover, name }: ViewMetaProps) {
  const coverType = useMemo(() => {
    if (cover && [CoverType.NormalColor, CoverType.GradientColor].includes(cover.type)) {
      return 'color';
    }

    if (CoverType.BuildInImage === cover?.type) {
      return 'built_in';
    }

    if (cover && [CoverType.CustomImage, CoverType.UpsplashImage].includes(cover.type)) {
      return 'custom';
    }
  }, [cover]);

  const coverValue = useMemo(() => {
    if (coverType === 'built_in') {
      return {
        1: BuiltInImage1,
        2: BuiltInImage2,
        3: BuiltInImage3,
        4: BuiltInImage4,
        5: BuiltInImage5,
        6: BuiltInImage6,
      }[cover?.value as string];
    }

    return cover?.value;
  }, [coverType, cover?.value]);
  const { t } = useTranslation();

  const isFlag = useMemo(() => {
    return icon ? isFlagEmoji(icon.value) : false;
  }, [icon]);

  return (
    <div className={'flex w-full flex-col items-center'}>
      {cover && <ViewCover coverType={coverType} coverValue={coverValue} />}
      <div
        className={`relative mb-6 mt-[52px] max-md:mt-[38px] px-6 w-[964px] min-w-0 max-w-full overflow-visible`}
      >
        <div
          className={
            'flex gap-4 overflow-hidden whitespace-pre-wrap break-words break-all text-[2.25rem] font-bold max-md:text-[26px]'
          }
        >
          {icon?.value ? <div className={`view-icon ${isFlag ? 'icon' : ''}`}>{icon?.value}</div> : null}

          <div className={'relative'}>
            {name || <span className={'text-text-placeholder'}>{t('menuAppHeader.defaultNewPageName')}</span>}
          </div>
        </div>
      </div>
    </div>
  );
}

export default ViewMetaPreview;
