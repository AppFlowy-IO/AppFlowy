import { useEffect, useMemo, useState } from 'react';

import Editor from '$app/components/editor/components/editor/Editor';
import { EditorProps } from '$app/application/document/document.types';
import { Provider } from '$app/components/editor/provider';
import { YXmlText } from 'yjs/dist/src/types/YXmlText';

export const CollaborativeEditor = ({ id, title, showTitle = true, onTitleChange }: EditorProps) => {
  const [sharedType, setSharedType] = useState<YXmlText | null>(null);
  const provider = useMemo(() => {
    setSharedType(null);
    return new Provider(id, showTitle);
  }, [id, showTitle]);

  const root = useMemo(() => {
    return showTitle ? (sharedType?.toDelta()[0].insert as YXmlText | null) : null;
  }, [sharedType, showTitle]);

  useEffect(() => {
    if (!root) return;

    const name = root.toString();

    if (name === title) return;

    if (root.length > 0) {
      root.delete(0, root.length);
    }

    root.insert(0, title || '');
  }, [title, root]);

  useEffect(() => {
    if (!root) return;
    const onChange = () => {
      onTitleChange?.(root.toString());
    };

    root.observe(onChange);
    return () => {
      root.unobserve(onChange);
    };
  }, [onTitleChange, root]);

  useEffect(() => {
    provider.connect();
    const handleConnected = () => {
      setSharedType(provider.sharedType);
    };

    provider.on('ready', handleConnected);
    return () => {
      setSharedType(null);
      provider.off('ready', handleConnected);
      provider.disconnect();
    };
  }, [provider]);

  if (!sharedType || id !== provider.id) {
    return null;
  }

  return <Editor sharedType={sharedType} />;
};
