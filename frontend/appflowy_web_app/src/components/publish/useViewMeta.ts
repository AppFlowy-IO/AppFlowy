import { usePublishContext } from '@/application/publish';
import { EditorLayoutStyle } from '@/components/editor/EditorContext';
import { ViewMetaCover } from '@/components/view-meta';
import { getFontFamily } from '@/utils/font';
import { useEffect, useMemo } from 'react';

export function useViewMeta() {
  const viewMeta = usePublishContext()?.viewMeta;

  const extra = useMemo(() => {
    try {
      return viewMeta?.extra ? JSON.parse(viewMeta.extra) : null;
    } catch (e) {
      return null;
    }
  }, [viewMeta?.extra]);

  const layoutStyle: EditorLayoutStyle = useMemo(() => {
    return {
      font: extra?.font || '',
      fontLayout: extra?.fontLayout,
      lineHeightLayout: extra?.lineHeightLayout,
    };
  }, [extra]);

  const layout = viewMeta?.layout;
  const style = useMemo(() => {
    const fontSizeMap = {
      small: '14px',
      normal: '16px',
      large: '20px',
    };

    return {
      fontFamily: layoutStyle.font,
      fontSize: fontSizeMap[layoutStyle.fontLayout],
    };
  }, [layoutStyle]);

  const layoutClassName = useMemo(() => {
    const classList = [];

    if (layoutStyle.fontLayout === 'large') {
      classList.push('font-large');
    } else if (layoutStyle.fontLayout === 'small') {
      classList.push('font-small');
    }

    if (layoutStyle.lineHeightLayout === 'large') {
      classList.push('line-height-large');
    } else if (layoutStyle.lineHeightLayout === 'small') {
      classList.push('line-height-small');
    }

    return classList.join(' ');
  }, [layoutStyle]);

  useEffect(() => {
    if (!layoutStyle.font) return;
    void getFontFamily(layoutStyle.font);
  }, [layoutStyle.font]);

  const icon = viewMeta?.icon || undefined;

  const cover = extra?.cover as ViewMetaCover;

  const viewId = viewMeta?.view_id;
  const name = viewMeta?.name;

  return {
    icon,
    cover,
    style,
    layoutClassName,
    layout,
    viewId,
    name,
  };
}
