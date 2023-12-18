import { useEffect, useMemo, useState } from 'react';

import Editor from '$app/components/editor/components/editor/Editor';
import { EditorProps } from '$app/application/document/document.types';
import { Provider } from '$app/components/editor/provider';
import { YXmlText } from 'yjs/dist/src/types/YXmlText';

export const CollaborativeEditor = (props: EditorProps) => {
  const [sharedType, setSharedType] = useState<YXmlText | null>(null);
  const provider = useMemo(() => {
    setSharedType(null);
    return new Provider(props.id);
  }, [props.id]);

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

  if (!sharedType || props.id !== provider.id) {
    return null;
  }

  return <Editor {...props} sharedType={sharedType || undefined} />;
};
