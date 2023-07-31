import React, { useMemo } from 'react';
import { BlockType, CoverType, NestedBlock } from '$app/interfaces/document';
import DocumentCover from '$app/components/document/DocumentTitle/cover/DocumentCover';
import DocumentIcon from '$app/components/document/DocumentTitle/DocumentIcon';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppSelector } from '$app/stores/store';

const heightCls = {
  cover: 'h-[220px]',
  icon: 'h-[80px]',
  coverAndIcon: 'h-[250px]',
  none: 'h-0',
};

function DocumentTopPanel({
  node,
  onUpdateCover,
  onUpdateIcon,
}: {
  node: NestedBlock<BlockType.PageBlock>;
  onUpdateCover: (coverType: CoverType | null, cover: string | null) => void;
  onUpdateIcon: (icon: string) => void;
}) {
  const { docId } = useSubscribeDocument();
  const icon = useAppSelector((state) => state.pages.pageMap[docId]?.icon);
  const { cover, coverType } = node.data;

  const className = useMemo(() => {
    if (cover && icon) return heightCls.coverAndIcon;
    if (cover) return heightCls.cover;
    if (icon) return heightCls.icon;
    return heightCls.none;
  }, [cover, icon]);

  return (
    <div
      style={{
        display: icon || cover ? 'block' : 'none',
      }}
      className={`relative ${className}`}
    >
      <DocumentCover onUpdateCover={onUpdateCover} className={heightCls.cover} cover={cover} coverType={coverType} />
      <DocumentIcon onUpdateIcon={onUpdateIcon} className={heightCls.icon} icon={icon} />
    </div>
  );
}

export default DocumentTopPanel;
