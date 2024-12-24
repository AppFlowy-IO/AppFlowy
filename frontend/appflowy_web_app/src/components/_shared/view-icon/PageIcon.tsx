import React, { useMemo } from 'react';
import { ViewIcon, ViewIconType, ViewLayout } from '@/application/types';
import { ReactComponent as BoardSvg } from '@/assets/board.svg';
import { ReactComponent as CalendarSvg } from '@/assets/calendar.svg';
import { ReactComponent as DocumentSvg } from '@/assets/document.svg';
import { ReactComponent as GridSvg } from '@/assets/grid.svg';
import { ReactComponent as ChatSvg } from '@/assets/chat_ai.svg';
import { isFlagEmoji } from '@/utils/emoji';
import DOMPurify from 'dompurify';
import { renderColor } from '@/utils/color';

function PageIcon({
  view,
  className,
}: {
  view: {
    icon?: ViewIcon | null;
    layout: ViewLayout;
  };
  className?: string;
}) {

  const emoji = useMemo(() => {
    if (view.icon && view.icon.ty === ViewIconType.Emoji) {
      return view.icon.value;
    }

    return null;
  }, [view]);

  const isFlag = useMemo(() => {
    return emoji ? isFlagEmoji(emoji) : false;
  }, [emoji]);

  const icon = useMemo(() => {
    if (view.icon && view.icon.ty === ViewIconType.Icon) {
      const json = JSON.parse(view.icon.value);
      const cleanSvg = DOMPurify.sanitize(json.iconContent.replaceAll('black', renderColor(json.color)).replace('<svg', '<svg width="100%" height="100%"'), {
        USE_PROFILES: { svg: true, svgFilters: true },
      });

      return <span className={`${className ? className : 'w-full h-full'} `} dangerouslySetInnerHTML={{
        __html: cleanSvg,
      }}/>;
    }
  }, [view, className]);

  if (emoji) {
    return <>
      <span className={`${isFlag ? 'icon' : ''} ${className || ''}`}>{emoji}</span>
    </>;
  }

  if (icon) {
    return icon;
  }

  switch (view.layout) {
    case ViewLayout.AIChat:
      return <ChatSvg className={className}/>;
    case ViewLayout.Grid:
      return <GridSvg className={className}/>;
    case ViewLayout.Board:
      return <BoardSvg className={className}/>;
    case ViewLayout.Calendar:
      return <CalendarSvg className={className}/>;
    case ViewLayout.Document:
      return <DocumentSvg className={className}/>;
    default:
      return null;
  }

}

export default PageIcon;