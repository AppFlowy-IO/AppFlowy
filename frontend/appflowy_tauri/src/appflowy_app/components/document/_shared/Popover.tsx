/**
 * @fileoverview
 * This component is a popover that can be used to display a menu or other content.
 * It is used in the Document components.
 * Why not use the MUI Popover component?
 * The MUI Popover component will snatch focus from the editor when it is opened.
 */

import { useCallback, useEffect, useMemo, useRef } from 'react';
import DocumentPortal from '$app/components/document/BlockPortal/DocumentPortal';
const marginThreshold = 16;

export enum Vertical {
  Top = 'top',
  Center = 'center',
  Bottom = 'bottom',
}
export enum Horizontal {
  Left = 'left',
  Center = 'center',
  Right = 'right',
}
interface Origin {
  vertical: Vertical | number;
  horizontal: Horizontal | number;
}

export interface PopoverProps {
  open: boolean;
  onClose: () => void;
  children?: JSX.Element | JSX.Element[];
  anchorEl?: HTMLElement | null;
  anchorOrigin?: Origin;
  transformOrigin?: Origin;
  className?: string;
}

function Popover({ open, onClose, children, ...props }: PopoverProps) {
  const ref = useRef<HTMLDivElement | null>(null);
  const className = useMemo(() => (props.className ? ` ${props.className}` : ''), [props.className]);
  const anchorEl = useMemo(() => (props.anchorEl ? props.anchorEl : document.body), [props.anchorEl]);
  const anchorOrigin = useMemo(
    () =>
      props.anchorOrigin
        ? props.anchorOrigin
        : {
            vertical: Vertical.Top,
            horizontal: Horizontal.Left,
          },
    [props.anchorOrigin]
  );
  const transformOrigin = useMemo(
    () =>
      props.transformOrigin
        ? props.transformOrigin
        : {
            vertical: Vertical.Top,
            horizontal: Horizontal.Left,
          },
    [props.transformOrigin]
  );

  const getAnchorOffset = useCallback(() => {
    const anchorRect = anchorEl.getBoundingClientRect();
    return {
      top: anchorRect.top + getOffsetTop(anchorRect, anchorOrigin.vertical),
      left: anchorRect.left + getOffsetLeft(anchorRect, anchorOrigin.horizontal),
    };
  }, [anchorEl, anchorOrigin.horizontal, anchorOrigin.vertical]);
  // Returns the base transform origin using the element
  const getTransformOrigin = useCallback(
    (elemRect: { width: number; height: number }) => {
      return {
        vertical: getOffsetTop(elemRect, transformOrigin.vertical),
        horizontal: getOffsetLeft(elemRect, transformOrigin.horizontal),
      };
    },
    [transformOrigin.horizontal, transformOrigin.vertical]
  );

  const getPositioningStyle = useCallback(
    (element: HTMLElement) => {
      const elemRect = {
        width: element.offsetWidth,
        height: element.offsetHeight,
      };

      // Get the transform origin point on the element itself
      const elemTransformOrigin = getTransformOrigin(elemRect);

      // Get the offset of the anchoring element
      const anchorOffset = getAnchorOffset();

      // Calculate element positioning
      let top = anchorOffset.top - elemTransformOrigin.vertical;
      let left = anchorOffset.left - elemTransformOrigin.horizontal;
      const bottom = top + elemRect.height;
      const right = left + elemRect.width;

      // Window thresholds taking required margin into account
      const heightThreshold = window.innerHeight - marginThreshold;
      const widthThreshold = window.innerWidth - marginThreshold;

      // Check if the vertical axis needs shifting
      if (top < marginThreshold) {
        const diff = top - marginThreshold;
        top -= diff;
        elemTransformOrigin.vertical += diff;
      } else if (bottom > heightThreshold) {
        const diff = bottom - heightThreshold;
        top -= diff;
        elemTransformOrigin.vertical += diff;
      }

      // Check if the horizontal axis needs shifting
      if (left < marginThreshold) {
        const diff = left - marginThreshold;
        left -= diff;
        elemTransformOrigin.horizontal += diff;
      } else if (right > widthThreshold) {
        const diff = right - widthThreshold;
        left -= diff;
        elemTransformOrigin.horizontal += diff;
      }

      return {
        top: `${Math.round(top)}px`,
        left: `${Math.round(left)}px`,
        transformOrigin: getTransformOriginValue(elemTransformOrigin),
      };
    },
    [getAnchorOffset, getTransformOrigin]
  );

  useEffect(() => {
    const element = ref.current;
    if (!open || !element) return;

    const style = getPositioningStyle(element);
    element.style.top = style.top;
    element.style.left = style.left;
    element.style.transformOrigin = style.transformOrigin;
  }, [getPositioningStyle, open]);

  if (!open) return null;

  return (
    <DocumentPortal>
      <div
        className='z-1 fixed inset-0 overflow-hidden'
        onScrollCapture={(e) => {
          // prevent scrolling of the document when menu is open
          e.stopPropagation();
        }}
        onClick={() => {
          // close the menu when clicking outside
          onClose();
        }}
      >
        <div
          ref={ref}
          className={`z-99 absolute flex flex-col items-start justify-items-start rounded bg-white p-4 shadow${className}`}
          onClick={(e) => {
            // prevent closing of the menu when clicking inside
            e.stopPropagation();
          }}
          onMouseDown={(e) => {
            // prevent focus loss when clicking inside
            e.preventDefault();
          }}
        >
          {children}
        </div>
      </div>
    </DocumentPortal>
  );
}

export default Popover;
function getTransformOriginValue(transformOrigin: Origin) {
  return [transformOrigin.horizontal, transformOrigin.vertical]
    .map((n) => (typeof n === 'number' ? `${n}px` : n))
    .join(' ');
}
export function getOffsetTop(
  rect: {
    width: number;
    height: number;
  },
  vertical: Vertical | number
) {
  let offset = 0;

  if (typeof vertical === 'number') {
    offset = vertical;
  } else if (vertical === Vertical.Center) {
    offset = rect.height / 2;
  } else if (vertical === Vertical.Bottom) {
    offset = rect.height;
  }

  return offset;
}

export function getOffsetLeft(
  rect: {
    width: number;
    height: number;
  },
  horizontal: Horizontal | number
) {
  let offset = 0;

  if (typeof horizontal === 'number') {
    offset = horizontal;
  } else if (horizontal === Horizontal.Center) {
    offset = rect.width / 2;
  } else if (horizontal === Horizontal.Right) {
    offset = rect.width;
  }

  return offset;
}
