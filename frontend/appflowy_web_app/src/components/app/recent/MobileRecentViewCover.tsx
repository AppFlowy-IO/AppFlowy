import { CoverType } from '@/application/types';

import ImageRender from '@/components/_shared/image-render/ImageRender';
import { renderColor } from '@/utils/color';
import React, { useCallback, useMemo } from 'react';

function MobileRecentViewCover ({ cover }: { cover: { type: string; value: string } }) {
  const renderCoverColor = useCallback((color: string) => {
    return (
      <div
        style={{
          background: renderColor(color),
        }}
        className={`h-full w-full`}
      />
    );
  }, []);

  const renderCoverImage = useCallback((url: string) => {
    return (
      <>
        <ImageRender
          draggable={false}
          src={url}
          alt={''}
          className={'h-full w-full object-cover'}
        />
      </>
    );
  }, []);

  const coverType = useMemo(() => {
    if (cover && [CoverType.NormalColor, CoverType.GradientColor].includes(cover.type as CoverType)) {
      return 'color';
    }

    if (CoverType.BuildInImage === cover?.type) {
      return 'built_in';
    }

    if (cover && [CoverType.CustomImage, CoverType.UpsplashImage].includes(cover.type as CoverType)) {
      return 'custom';
    }
  }, [cover]);

  const coverValue = useMemo(() => {
    if (coverType === 'built_in') {
      return {
        1: '/covers/m_cover_image_1.png',
        2: '/covers/m_cover_image_2.png',
        3: '/covers/m_cover_image_3.png',
        4: '/covers/m_cover_image_4.png',
        5: '/covers/m_cover_image_5.png',
        6: '/covers/m_cover_image_6.png',
      }[cover.value];
    }

    return cover.value;
  }, [coverType, cover.value]);

  if (!coverType || !coverValue) {
    return null;
  }

  return (
    <div className={'w-[78px] rounded-[8px] overflow-hidden h-[54px]'}>
      {coverType === 'color' && renderCoverColor(coverValue)}
      {(coverType === 'custom' || coverType === 'built_in') && renderCoverImage(coverValue)}
    </div>
  );
}

export default MobileRecentViewCover;