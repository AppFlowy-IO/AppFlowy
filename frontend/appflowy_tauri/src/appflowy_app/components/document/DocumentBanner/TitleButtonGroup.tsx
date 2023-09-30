import React, { useCallback } from 'react';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { EmojiEmotionsOutlined, ImageOutlined } from '@mui/icons-material';
import { BlockType, CoverType, NestedBlock } from '$app/interfaces/document';
import { randomColor } from '$app/components/document/DocumentBanner/cover/config';
import { randomEmoji } from '$app/utils/document/emoji';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppSelector } from '$app/stores/store';

interface Props {
  node: NestedBlock<BlockType.PageBlock>;
  onUpdateCover: (coverType: CoverType, cover: string) => void;
  onUpdateIcon: (icon: string) => void;
}
function TitleButtonGroup({ onUpdateIcon, onUpdateCover, node }: Props) {
  const { t } = useTranslation();
  const { docId } = useSubscribeDocument();
  const icon = useAppSelector((state) => state.pages.pageMap[docId]?.icon);

  const showAddIcon = !icon;
  const showAddCover = !node.data.cover;

  const onAddIcon = useCallback(() => {
    const emoji = randomEmoji();

    onUpdateIcon(emoji);
  }, [onUpdateIcon]);

  const onAddCover = useCallback(() => {
    const color = randomColor();

    onUpdateCover(CoverType.Color, color);
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
