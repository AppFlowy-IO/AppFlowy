import { Scrollbars } from 'react-custom-scrollbars-2';
import React from 'react';

export interface AFScrollerProps {
  children: React.ReactNode;
  overflowXHidden?: boolean;
  overflowYHidden?: boolean;
  className?: string;
  style?: React.CSSProperties;
  onScroll?: (e: React.UIEvent<unknown>) => void;
}

export const AFScroller = React.forwardRef(
  ({ onScroll, style, children, overflowXHidden, overflowYHidden, className }: AFScrollerProps, ref) => {
    return (
      <Scrollbars
        onScroll={onScroll}
        autoHide
        hideTracksWhenNotNeeded
        ref={(el) => {
          if (!el) return;

          const scrollEl = el.container?.firstChild as HTMLElement;

          if (!scrollEl) return;
          if (typeof ref === 'function') {
            ref(scrollEl);
          } else if (ref) {
            ref.current = scrollEl;
          }
        }}
        renderTrackHorizontal={(props) => <div {...props} className='appflowy-scrollbar-track-horizontal' />}
        renderTrackVertical={(props) => <div {...props} className='appflowy-scrollbar-track-vertical' />}
        renderThumbHorizontal={(props) => <div {...props} className='appflowy-scrollbar-thumb-horizontal' />}
        renderThumbVertical={(props) => <div {...props} className='appflowy-scrollbar-thumb-vertical' />}
        {...(overflowXHidden && {
          renderTrackHorizontal: (props) => (
            <div
              {...props}
              style={{
                display: 'none',
              }}
            />
          ),
        })}
        {...(overflowYHidden && {
          renderTrackVertical: (props) => (
            <div
              {...props}
              style={{
                display: 'none',
              }}
            />
          ),
        })}
        style={style}
        renderView={(props) => (
          <div
            {...props}
            style={{
              ...props.style,
              overflowX: overflowXHidden ? 'hidden' : 'auto',
              overflowY: overflowYHidden ? 'hidden' : 'auto',
              marginRight: 0,
              marginBottom: 0,
            }}
            className={`${className} appflowy-custom-scroller`}
          />
        )}
      >
        {children}
      </Scrollbars>
    );
  }
);
