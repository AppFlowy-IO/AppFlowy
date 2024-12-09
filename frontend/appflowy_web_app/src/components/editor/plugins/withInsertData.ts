import { CustomEditor } from '@/application/slate-yjs/command';
import { YjsEditor } from '@/application/slate-yjs';
import { getBlockEntry } from '@/application/slate-yjs/utils/yjsOperations';
import { ReactEditor } from 'slate-react';
import { BlockType, FieldURLType, FileBlockData, ImageBlockData, ImageType } from '@/application/types';
import { MAX_IMAGE_SIZE } from '@/components/_shared/image-upload';
import { FileHandler } from '@/utils/file';

export const withInsertData = (editor: ReactEditor) => {
  const { insertData } = editor;

  const e = editor as YjsEditor;

  editor.insertData = (data: DataTransfer) => {
    // Do something with the data...
    const fileArray = Array.from(data.files);
    const { selection } = editor;
    const blockId = getBlockEntry(e)[0].blockId;

    insertData(data);

    if (blockId && fileArray.length > 0 && selection) {
      void (async () => {
        for (const file of fileArray) {
          if (file.size > MAX_IMAGE_SIZE) {
            return;
          }

          const url = await e.uploadFile?.(file);
          let fileId = '';

          if (!url) {
            const fileHandler = new FileHandler();
            const res = await fileHandler.handleFileUpload(file);

            fileId = res.id;
          }

          const isImage = file.type.startsWith('image/');

          if (isImage) {
            const data = {
              url: url,
              image_type: ImageType.External,
            } as ImageBlockData;

            if (fileId) {
              data.retry_local_url = fileId;
            }

            // Handle images...
            CustomEditor.addBelowBlock(e, blockId, BlockType.ImageBlock, data);
          } else {
            const data = {
              url: url,
              name: file.name,
              uploaded_at: Date.now(),
              url_type: FieldURLType.Upload,
            } as FileBlockData;

            if (fileId) {
              data.retry_local_url = fileId;
            }

            // Handle files...
            CustomEditor.addBelowBlock(e, blockId, BlockType.FileBlock, data);
          }

        }
      })();

    }
  };

  return editor;
};