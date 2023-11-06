import { heightCls, useDocumentBanner } from './DocumentBanner.hooks';
import TitleButtonGroup from './TitleButtonGroup';
import DocumentCover from './cover/DocumentCover';
import DocumentIcon from './DocumentIcon';

function DocumentBanner({ id, hover }: { id: string; hover: boolean }) {
  const { onUpdateCover, node, onUpdateIcon, icon, cover, className, coverType } = useDocumentBanner(id);

  return (
    <>
      <div
        style={{
          display: icon || cover ? 'block' : 'none',
        }}
        className={`relative ${className}`}
      >
        <DocumentCover onUpdateCover={onUpdateCover} className={heightCls.cover} cover={cover} coverType={coverType} />
        <DocumentIcon onUpdateIcon={onUpdateIcon} className={heightCls.icon} icon={icon} />
      </div>
      <div
        style={{
          opacity: hover ? 1 : 0,
        }}
      >
        <TitleButtonGroup node={node} onUpdateCover={onUpdateCover} onUpdateIcon={onUpdateIcon} />
      </div>
    </>
  );
}

export default DocumentBanner;
