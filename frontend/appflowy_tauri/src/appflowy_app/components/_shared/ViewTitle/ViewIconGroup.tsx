import { useTranslation } from 'react-i18next';
import { PageIcon } from '$app_reducers/pages/slice';
import React, { useCallback } from 'react';
import { randomEmoji } from '$app/utils/document/emoji';
import { EmojiEmotionsOutlined } from '@mui/icons-material';
import Button from '@mui/material/Button';

interface Props {
  icon?: PageIcon;
  // onUpdateCover: (coverType: CoverType, cover: string) => void;
  onUpdateIcon: (icon: string) => void;
}
function ViewIconGroup({ icon, onUpdateIcon }: Props) {
  const { t } = useTranslation();

  const showAddIcon = !icon;

  const onAddIcon = useCallback(() => {
    const emoji = randomEmoji();

    onUpdateIcon(emoji);
  }, [onUpdateIcon]);

  // const onAddCover = useCallback(() => {
  //   const color = randomColor();
  //
  //   onUpdateCover(CoverType.Color, color);
  // }, []);

  return (
    <div className={'flex items-center py-2'}>
      {showAddIcon && (
        <Button onClick={onAddIcon} color={'inherit'} startIcon={<EmojiEmotionsOutlined />}>
          {t('document.plugins.cover.addIcon')}
        </Button>
      )}
      {/*{showAddCover && (*/}
      {/*  <Button onClick={onAddCover} color={'inherit'} startIcon={<ImageOutlined />}>*/}
      {/*    {t('document.plugins.cover.addCover')}*/}
      {/*  </Button>*/}
      {/*)}*/}
    </div>
  );
}

export default ViewIconGroup;
