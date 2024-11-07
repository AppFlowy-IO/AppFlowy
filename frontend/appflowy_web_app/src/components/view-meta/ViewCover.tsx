import { ViewMetaCover } from '@/application/types';
import ImageRender from '@/components/_shared/image-render/ImageRender';
import { renderColor } from '@/utils/color';
import { PopoverProps } from '@mui/material/Popover';
import React, { lazy, useCallback, useRef, useState, Suspense } from 'react';

const CoverPopover = lazy(() => import('@/components/view-meta/CoverPopover'));
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
  const [anchorPosition, setAnchorPosition] = useState<PopoverProps['anchorPosition']>(undefined);
  const showPopover = Boolean(anchorPosition);
  const actionRef = useRef<HTMLDivElement>(null);

  const handleClickChange = useCallback((event: React.MouseEvent<HTMLDivElement>) => {
    if (readOnly) return;
    setAnchorPosition({
      top: event.clientY,
      left: event.clientX,
    });
  }, [readOnly]);

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
      <Suspense>
        <ViewCoverActions
          show={showAction}
          ref={actionRef}
          onRemove={onRemoveCover}
          onClick={handleClickChange}
        />
        {showPopover && <CoverPopover
          anchorPosition={anchorPosition}
          open={
            showPopover
          }
          onClose={
            () => setAnchorPosition(undefined)
          }
          onUpdateCover={onUpdateCover}
        />}
      </Suspense>

    </div>
  );
}

export default ViewCover;

