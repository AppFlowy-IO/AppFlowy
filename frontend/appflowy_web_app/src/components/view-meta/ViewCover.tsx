import { renderColor } from '@/utils/color';
import React, { useCallback } from 'react';

function ViewCover({ coverValue, coverType }: { coverValue?: string; coverType?: string }) {
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
    return <img draggable={false} src={url} alt={''} className={'h-full w-full object-cover'} />;
  }, []);

  if (!coverType || !coverValue) {
    return null;
  }

  return (
    <div className={'relative flex h-[208px] w-full max-sm:h-[180px]'}>
      {coverType === 'color' && renderCoverColor(coverValue)}
      {(coverType === 'custom' || coverType === 'built_in') && renderCoverImage(coverValue)}
    </div>
  );
}

export default ViewCover;

export enum CoverType {
  NormalColor = 'color',
  GradientColor = 'gradient',
  BuildInImage = 'built_in',
  CustomImage = 'custom',
  LocalImage = 'local',
  UpsplashImage = 'unsplash',
  None = 'none',
}
