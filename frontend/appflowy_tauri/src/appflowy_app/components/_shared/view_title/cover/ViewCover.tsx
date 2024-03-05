import React, { useCallback, useMemo, useRef, useState } from 'react';
import { CoverType, PageCover } from '$app_reducers/pages/slice';
import { renderColor } from '$app/utils/color';
import ViewCoverActions from '$app/components/_shared/view_title/cover/ViewCoverActions';
import CoverPopover from '$app/components/_shared/view_title/cover/CoverPopover';
import DefaultImage from '$app/assets/images/default_cover.jpg';
import { ImageType } from '$app/application/document/document.types';
import { LocalImage } from '$app/components/_shared/image_upload';

export function ViewCover({ cover, onUpdateCover }: { cover: PageCover; onUpdateCover?: (cover?: PageCover) => void }) {
  const {
    cover_selection_type: type,
    cover_selection: value = '',
    image_type: source,
  } = useMemo(() => cover || {}, [cover]);
  const [showAction, setShowAction] = useState(false);
  const actionRef = useRef<HTMLDivElement>(null);
  const [showPopover, setShowPopover] = useState(false);

  const renderCoverColor = useCallback((color: string) => {
    return (
      <div
        style={{
          backgroundColor: renderColor(color),
        }}
        className={`h-full w-full`}
      />
    );
  }, []);

  const renderCoverImage = useCallback((url: string) => {
    return <img draggable={false} src={url} alt={''} className={'h-full w-full object-cover'} />;
  }, []);

  const handleRemoveCover = useCallback(() => {
    onUpdateCover?.(null);
  }, [onUpdateCover]);

  const handleClickChange = useCallback(() => {
    setShowPopover(true);
  }, []);

  return (
    <div
      onMouseEnter={() => {
        setShowAction(true);
      }}
      onMouseLeave={() => {
        setShowAction(false);
      }}
      className={'relative flex h-[255px] w-full'}
    >
      {source === ImageType.Local ? (
        <LocalImage src={value} className={'h-full w-full object-cover'} />
      ) : (
        <>
          {type === CoverType.Asset ? renderCoverImage(DefaultImage) : null}
          {type === CoverType.Color ? renderCoverColor(value) : null}
          {type === CoverType.Image ? renderCoverImage(value) : null}
        </>
      )}

      <ViewCoverActions
        show={showAction}
        ref={actionRef}
        onRemove={handleRemoveCover}
        onClickChange={handleClickChange}
      />
      {showPopover && (
        <CoverPopover
          open={showPopover}
          onClose={() => setShowPopover(false)}
          anchorEl={actionRef.current}
          onUpdateCover={onUpdateCover}
          onRemoveCover={handleRemoveCover}
        />
      )}
    </div>
  );
}
