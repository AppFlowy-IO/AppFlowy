import { memo, useEffect, useMemo, useState } from 'react';

import Editor from '$app/components/editor/components/editor/Editor';
import { EditorProps } from '$app/application/document/document.types';
import { Provider } from '$app/components/editor/provider';
import { YXmlText } from 'yjs/dist/src/types/YXmlText';
import { getInsertTarget, getYTarget } from '$app/components/editor/provider/utils/relation';
import isEqual from 'lodash-es/isEqual';

export const CollaborativeEditor = memo(
  ({ id, title, cover, showTitle = true, onTitleChange, onCoverChange, ...props }: EditorProps) => {
    const [sharedType, setSharedType] = useState<YXmlText | null>(null);
    const provider = useMemo(() => {
      setSharedType(null);

      return new Provider(id);
    }, [id]);

    const root = useMemo(() => {
      if (!showTitle || !sharedType || !sharedType.doc) return null;

      return getYTarget(sharedType?.doc, [0]);
    }, [sharedType, showTitle]);

    const rootText = useMemo(() => {
      if (!root) return null;
      return getInsertTarget(root, [0]);
    }, [root]);

    useEffect(() => {
      if (!rootText || rootText.toString() === title) return;

      if (rootText.length > 0) {
        rootText.delete(0, rootText.length);
      }

      rootText.insert(0, title || '');
    }, [title, rootText]);

    useEffect(() => {
      if (!root) return;

      const originalCover = root.getAttribute('data')?.cover;

      if (cover === undefined) return;
      if (isEqual(originalCover, cover)) return;
      root.setAttribute('data', { cover: cover ? cover : undefined });
    }, [cover, root]);

    useEffect(() => {
      if (!root) return;
      const rootId = root.getAttribute('blockId');

      if (!rootId) return;

      const getCover = () => {
        const data = root.getAttribute('data');

        onCoverChange?.(data?.cover);
      };

      getCover();
      const onChange = () => {
        onTitleChange?.(root.toString());
        getCover();
      };

      root.observeDeep(onChange);
      return () => root.unobserveDeep(onChange);
    }, [onTitleChange, root, onCoverChange]);

    useEffect(() => {
      provider.connect();

      const handleConnected = () => {
        setSharedType(provider.sharedType);
      };

      provider.on('ready', handleConnected);
      void provider.initialDocument(showTitle);
      return () => {
        provider.off('ready', handleConnected);
        provider.disconnect();
      };
    }, [provider, showTitle]);

    if (!sharedType || id !== provider.id) {
      return null;
    }

    return <Editor sharedType={sharedType} id={id} {...props} />;
  }
);
