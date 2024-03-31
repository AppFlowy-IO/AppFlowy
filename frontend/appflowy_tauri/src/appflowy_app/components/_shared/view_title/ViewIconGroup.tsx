import { useTranslation } from 'react-i18next';
import { CoverType, PageCover, PageIcon } from '$app_reducers/pages/slice';
import React, { useCallback } from 'react';
import { randomEmoji } from '$app/utils/emoji';
import { EmojiEmotionsOutlined } from '@mui/icons-material';
import Button from '@mui/material/Button';
import { ReactComponent as ImageIcon } from '$app/assets/image.svg';
import { ImageType } from '$app/application/document/document.types';

interface Props {
  icon?: PageIcon;
  onUpdateIcon: (icon: string) => void;
  showCover: boolean;
  cover?: PageCover;
  onUpdateCover?: (cover: PageCover) => void;
}

const defaultCover = {
  cover_selection_type: CoverType.Asset,
  cover_selection: 'app_flowy_abstract_cover_2.jpeg',
  image_type: ImageType.Internal,
};

function ViewIconGroup({ icon, onUpdateIcon, showCover, cover, onUpdateCover }: Props) {
  const { t } = useTranslation();

  const showAddIcon = !icon?.value;

  const showAddCover = !cover && showCover;

  const onAddIcon = useCallback(() => {
    const emoji = randomEmoji();

    onUpdateIcon(emoji);
  }, [onUpdateIcon]);

  const onAddCover = useCallback(() => {
    onUpdateCover?.(defaultCover);
  }, [onUpdateCover]);

  return (
    <div className={'flex items-center py-1'}>
      {showAddIcon && (
        <Button size={'small'} onClick={onAddIcon} color={'inherit'} startIcon={<EmojiEmotionsOutlined />}>
          {t('document.plugins.cover.addIcon')}
        </Button>
      )}
      {showAddCover && (
        <Button size={'small'} onClick={onAddCover} color={'inherit'} startIcon={<ImageIcon />}>
          {t('document.plugins.cover.addCover')}
        </Button>
      )}
    </div>
  );
}

export default ViewIconGroup;
