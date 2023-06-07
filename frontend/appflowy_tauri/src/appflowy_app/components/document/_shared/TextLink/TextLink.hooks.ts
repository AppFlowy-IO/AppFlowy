import { useCallback, useMemo, useRef, useState } from 'react';
import { debounce } from '$app/utils/tool';

export function useTextLink(id: string) {
  const [editing, setEditing] = useState(false);
  const ref = useRef<HTMLAnchorElement | null>(null);

  const show = useMemo(() => debounce(() => setEditing(true), 500), []);
  const hide = useMemo(() => debounce(() => setEditing(false), 500), []);

  const onMouseEnter = useCallback(() => {
    hide.cancel();
    show();
  }, [hide, show]);

  const onMouseLeave = useCallback(() => {
    show.cancel();
    hide();
  }, [hide, show]);

  return {
    editing,
    onMouseEnter,
    onMouseLeave,
    ref,
  };
}
