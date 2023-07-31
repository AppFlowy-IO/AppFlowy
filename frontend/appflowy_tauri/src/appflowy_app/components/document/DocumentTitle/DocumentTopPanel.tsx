import React, { useEffect, useMemo } from 'react';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import DocumentCover from '$app/components/document/DocumentTitle/cover/DocumentCover';
import DocumentIcon from '$app/components/document/DocumentTitle/DocumentIcon';

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
  onUpdateCover: (coverType: 'image' | 'color' | '', cover: string) => void;
  onUpdateIcon: (icon: string) => void;
}) {
  const { cover, coverType, icon } = node.data;

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
