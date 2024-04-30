import { Scrollbars } from 'react-custom-scrollbars';
import React from 'react';

export interface AFScrollerProps {
  children: React.ReactNode;
  overflowXHidden?: boolean;
  overflowYHidden?: boolean;
  className?: string;
  style?: React.CSSProperties;
}
export const AFScroller = ({ style, children, overflowXHidden, overflowYHidden, className }: AFScrollerProps) => {
  return (
    <Scrollbars
      autoHide
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
          className={className}
        />
      )}
    >
      {children}
    </Scrollbars>
  );
};
