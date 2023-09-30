import React, { useCallback, useState } from 'react';
import { DeleteOutlineRounded } from '@mui/icons-material';
import { useTranslation } from 'react-i18next';
import ChangeCoverPopover from '$app/components/document/DocumentBanner/cover/ChangeCoverPopover';
import { CoverType } from '$app/interfaces/document';

function ChangeCoverButton({
  visible,
  cover,
  coverType,
  onUpdateCover,
}: {
  visible: boolean;
  cover: string;
  coverType: CoverType;
  onUpdateCover: (coverType: CoverType | null, cover: string | null) => void;
}) {
  const { t } = useTranslation();
  const [anchorPosition, setAnchorPosition] = useState<undefined | { top: number; left: number }>(undefined);
  const open = Boolean(anchorPosition);
  const onClose = useCallback(() => {
    setAnchorPosition(undefined);
  }, []);
  const onOpen = useCallback((event: React.MouseEvent<HTMLButtonElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();

    setAnchorPosition({
      top: rect.top + rect.height,
      left: rect.left + rect.width + 40,
    });
  }, []);

  const onDeleteCover = useCallback(() => {
    onUpdateCover(null, null);
  }, [onUpdateCover]);

  return (
    <>
      {visible && (
        <div className={'absolute bottom-4 right-6 flex text-[0.7rem]'}>
          <button
            onClick={onOpen}
            className={
              'flex items-center rounded-md border border-line-divider bg-bg-body p-1 px-2 opacity-70 hover:opacity-100'
            }
          >
            {t('document.plugins.cover.changeCover')}
          </button>
          <button
            className={
              'ml-2 flex items-center rounded-md border border-line-divider bg-bg-body p-1 opacity-70 hover:opacity-100'
            }
            onClick={onDeleteCover}
          >
            <DeleteOutlineRounded />
          </button>
        </div>
      )}
      <ChangeCoverPopover
        cover={cover}
        coverType={coverType}
        open={open}
        anchorPosition={anchorPosition}
        onClose={onClose}
        onUpdateCover={onUpdateCover}
      />
    </>
  );
}

export default ChangeCoverButton;
