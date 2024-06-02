import { DocCover, YBlocks, YDoc, YDocument, YjsEditorKey } from '@/application/collab.type';
import { useEffect, useMemo, useState } from 'react';

export function useBlockCover(doc: YDoc) {
  const [cover, setCover] = useState<string | null>(null);

  useEffect(() => {
    if (!doc) return;

    const document = doc.getMap(YjsEditorKey.data_section).get(YjsEditorKey.document) as YDocument;
    const pageId = document.get(YjsEditorKey.page_id) as string;
    const blocks = document.get(YjsEditorKey.blocks) as YBlocks;
    const root = blocks.get(pageId);

    setCover(root.toJSON().data || null);
    const observerEvent = () => setCover(root.toJSON().data || null);

    root.observe(observerEvent);

    return () => {
      root.unobserve(observerEvent);
    };
  }, [doc]);

  const coverObj: DocCover = useMemo(() => {
    try {
      return JSON.parse(cover || '');
    } catch (e) {
      return null;
    }
  }, [cover]);

  return {
    cover: coverObj,
  };
}
