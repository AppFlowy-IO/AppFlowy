import React, { useCallback } from 'react';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { EmojiEmotionsOutlined, ImageOutlined } from '@mui/icons-material';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import { randomColor } from '$app/components/document/DocumentTitle/cover/config';
import { randomEmoji } from '$app/utils/document/emoji';

interface Props {
  node: NestedBlock<BlockType.PageBlock>;
  onUpdateCover: (coverType: 'image' | 'color', cover: string) => void;
  onUpdateIcon: (icon: string) => void;
}
function TitleButtonGroup({ onUpdateIcon, onUpdateCover, node }: Props) {
  const { t } = useTranslation();
  const showAddIcon = !node.data.icon;
  const showAddCover = !node.data.cover;

  const onAddIcon = useCallback(() => {
    const emoji = randomEmoji();

    onUpdateIcon(emoji);
  }, [onUpdateIcon]);

  const onAddCover = useCallback(() => {
    const color = randomColor();

    onUpdateCover('color', color);
  }, [onUpdateCover]);

  return (
    <div className={'flex items-center py-2'}>
      {showAddIcon && (
        <Button onClick={onAddIcon} color={'inherit'} startIcon={<EmojiEmotionsOutlined />}>
          {t('document.plugins.cover.addIcon')}
        </Button>
      )}
      {showAddCover && (
        <Button onClick={onAddCover} color={'inherit'} startIcon={<ImageOutlined />}>
          {t('document.plugins.cover.addCover')}
        </Button>
      )}
    </div>
  );
}

export default TitleButtonGroup;
