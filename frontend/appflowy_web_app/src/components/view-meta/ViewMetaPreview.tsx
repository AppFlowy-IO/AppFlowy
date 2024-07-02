import BuiltInImage1 from '@/assets/cover/m_cover_image_1.png';
import BuiltInImage2 from '@/assets/cover/m_cover_image_2.png';
import BuiltInImage3 from '@/assets/cover/m_cover_image_3.png';
import BuiltInImage4 from '@/assets/cover/m_cover_image_4.png';
import BuiltInImage5 from '@/assets/cover/m_cover_image_5.png';
import BuiltInImage6 from '@/assets/cover/m_cover_image_6.png';
import ViewCover, { CoverType } from '@/components/view-meta/ViewCover';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ViewMetaIcon } from '@/application/collab.type';

export interface ViewMetaCover {
  type: CoverType;
  value: string;
}

export interface ViewMetaProps {
  icon?: ViewMetaIcon;
  cover?: ViewMetaCover;
  name?: string;
  viewId?: string;
}

export function ViewMetaPreview({ icon, cover, name }: ViewMetaProps) {
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

  return (
    <div className={'flex w-full flex-col items-center'}>
      {cover && <ViewCover coverType={coverType} coverValue={coverValue} />}
      <div className={`relative mx-16 mb-6 mt-[52px] w-[964px] min-w-0 max-w-full overflow-visible max-md:mx-4`}>
        <div
          className={
            'flex items-center gap-4 px-16 text-[2.25rem] font-bold leading-[1.5em] max-md:px-4 max-sm:text-[7vw]'
          }
        >
          {icon?.value ? <div className={'view-icon'}>{icon?.value}</div> : null}

          {name || <span className={'text-text-placeholder'}>{t('menuAppHeader.defaultNewPageName')}</span>}
        </div>
      </div>
    </div>
  );
}

export default ViewMetaPreview;
