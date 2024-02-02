import { PopoverOrigin } from '@mui/material/Popover/Popover';

export function getOffsetTop(rect: DOMRect, vertical: number | 'center' | 'bottom' | 'top') {
  let offset = 0;

  if (typeof vertical === 'number') {
    offset = vertical;
  } else if (vertical === 'center') {
    offset = rect.height / 2;
  } else if (vertical === 'bottom') {
    offset = rect.height;
  }

  return offset;
}

export function getOffsetLeft(rect: DOMRect, horizontal: number | 'center' | 'left' | 'right') {
  let offset = 0;

  if (typeof horizontal === 'number') {
    offset = horizontal;
  } else if (horizontal === 'center') {
    offset = rect.width / 2;
  } else if (horizontal === 'right') {
    offset = rect.width;
  }

  return offset;
}

export function getAnchorOffset(anchorElement: HTMLElement, anchorOrigin: PopoverOrigin) {
  const anchorRect = anchorElement.getBoundingClientRect();

  return {
    top: anchorRect.top + getOffsetTop(anchorRect, anchorOrigin.vertical),
    left: anchorRect.left + getOffsetLeft(anchorRect, anchorOrigin.horizontal),
  };
}

export function getTransformOrigin(elemRect: DOMRect, transformOrigin: PopoverOrigin) {
  return {
    vertical: getOffsetTop(elemRect, transformOrigin.vertical),
    horizontal: getOffsetLeft(elemRect, transformOrigin.horizontal),
  };
}
