import { ViewMetaCover } from '@/application/types';
import ImageRender from '@/components/_shared/image-render/ImageRender';
import { renderColor } from '@/utils/color';
import React, { lazy, useCallback, useRef, useState, Suspense } from 'react';

const ViewCoverActions = lazy(() => import('@/components/view-meta/ViewCoverActions'));

function ViewCover ({ coverValue, coverType, onUpdateCover, onRemoveCover, readOnly = true }: {
  coverValue?: string;
  coverType?: string;
  onUpdateCover: (cover: ViewMetaCover) => void;
  onRemoveCover: () => void;
  readOnly?: boolean
}) {
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

  const [showAction, setShowAction] = useState(false);

  const actionRef = useRef<HTMLDivElement>(null);

  if (!coverType || !coverValue) {
    return null;
  }

  return (
    <div
      onMouseEnter={() => {
        if (readOnly) return;
        setShowAction(true);
      }}
      onMouseLeave={() => {
        setShowAction(false);
      }}
      style={{
        height: '40vh',
      }}
      className={'relative flex max-h-[288px] min-h-[130px] w-full max-sm:h-[180px]'}
    >
      {coverType === 'color' && renderCoverColor(coverValue)}
      {(coverType === 'custom' || coverType === 'built_in') && renderCoverImage(coverValue)}
      {!readOnly && <Suspense>
        <ViewCoverActions
          show={showAction}
          ref={actionRef}
          onUpdateCover={onUpdateCover}
          onRemove={onRemoveCover}
        />
      </Suspense>
      }

    </div>
  );
}

export default ViewCover;

