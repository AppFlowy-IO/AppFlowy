import { CustomEditor } from '@/application/slate-yjs/command';
import { YjsEditor } from '@/application/slate-yjs';
import { findSlateEntryByBlockId, getBlockEntry } from '@/application/slate-yjs/utils/editor';
import { ReactEditor } from 'slate-react';
import { BlockType, FieldURLType, FileBlockData, ImageBlockData, ImageType } from '@/application/types';
import { FileHandler } from '@/utils/file';
import { convertSlateFragmentTo } from '@/components/editor/utils/fragment';
import { Node } from 'slate';

export const withInsertData = (editor: ReactEditor) => {
  const { insertData } = editor;

  const e = editor as YjsEditor;

  editor.insertData = (data: DataTransfer) => {
    const fragment = data.getData('application/x-slate-fragment');

    if (fragment) {
      const decoded = decodeURIComponent(window.atob(fragment));
      const parsed = JSON.parse(decoded) as Node[];
      const newFragment = convertSlateFragmentTo(parsed);

      return e.insertFragment(newFragment);
    }

    // Do something with the data...
    const fileArray = Array.from(data.files);
    const { selection } = editor;
    const entry = getBlockEntry(e);
    const [node] = entry;
    const blockId = node.blockId;

    insertData(data);

    if (blockId && fileArray.length > 0 && selection) {
      void (async () => {
        const text = CustomEditor.getBlockTextContent(node);
        let newBlockId: string = blockId;

        for (const file of fileArray) {
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
            newBlockId = CustomEditor.addBelowBlock(e, newBlockId, BlockType.ImageBlock, data) || newBlockId;
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
            newBlockId = CustomEditor.addBelowBlock(e, newBlockId, BlockType.FileBlock, data) || newBlockId;
          }

        }

        if (!text) {
          CustomEditor.deleteBlock(e, blockId);
        }

        const firstIsImage = fileArray[0].type.startsWith('image/');

        if (newBlockId && firstIsImage) {
          const id = CustomEditor.addBelowBlock(e, newBlockId, BlockType.Paragraph, {});

          if (!id) return;

          const [, path] = findSlateEntryByBlockId(e, id);

          editor.select(editor.start(path));

        }

      })();

    }
  };

  return editor;
};