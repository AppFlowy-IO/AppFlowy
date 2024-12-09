import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { GalleryPreview } from '@/components/_shared/gallery-preview';
import { notify } from '@/components/_shared/notify';
import ActionButton from '@/components/editor/components/toolbar/selection-toolbar/actions/ActionButton';
import Align from '@/components/editor/components/toolbar/selection-toolbar/actions/Align';
import { ImageBlockNode } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import { Divider } from '@mui/material';
import React, { Suspense } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as CopyIcon } from '@/assets/copy.svg';
import { ReactComponent as PreviewIcon } from '@/assets/full_view.svg';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import { useReadOnly, useSlateStatic } from 'slate-react';

function ImageToolbar({ node }: {
  node: ImageBlockNode
}) {
  const editor = useSlateStatic() as YjsEditor;
  const readOnly = useReadOnly();
  const { t } = useTranslation();
  const [openPreview, setOpenPreview] = React.useState(false);

  const onOpenPreview = () => {
    setOpenPreview(true);
  };

  const onCopy = async () => {
    await copyTextToClipboard(node.data.url || '');
    notify.success(t('document.plugins.image.copiedToPasteBoard'));
  };

  const onDelete = () => {
    CustomEditor.deleteBlock(editor, node.blockId);
  };

  return (
    <div className={'absolute z-10 top-0 right-0'}>
      <div className={'flex space-x-1 rounded-[8px] p-1 bg-fill-toolbar shadow border border-line-divider '}>
        {!readOnly && <ActionButton
          onClick={onOpenPreview}
          tooltip={t('document.imageBlock.openFullScreen')}
        >
          <PreviewIcon/>
        </ActionButton>}

        <ActionButton
          onClick={onCopy}
          tooltip={t('button.copyLinkOriginal')}
        >
          <CopyIcon/>
        </ActionButton>

        {!readOnly && <>
          <Align
            blockId={node.blockId}
          />
          <Divider
            className={'my-1.5 bg-line-on-toolbar'}
            orientation={'vertical'}
            flexItem={true}
          />
          <ActionButton
            onClick={onDelete}
            tooltip={t('button.delete')}
          >
            <DeleteIcon/>
          </ActionButton></>}

      </div>
      {openPreview && <Suspense><GalleryPreview
        images={[{ src: node.data.url || '' }]}
        previewIndex={0}
        open={openPreview}
        onClose={() => {
          setOpenPreview(false);
        }}
      /></Suspense>}
    </div>
  );
}

export default ImageToolbar;