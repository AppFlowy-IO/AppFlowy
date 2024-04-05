import { useState, useEffect, useCallback } from 'react';
import { PopoverOrigin } from '@mui/material/Popover/Popover';

interface PopoverPosition {
  anchorOrigin: PopoverOrigin;
  transformOrigin: PopoverOrigin;
  paperWidth: number;
  paperHeight: number;
  isEntered: boolean;
  anchorPosition?: { left: number; top: number };
}

interface UsePopoverAutoPositionProps {
  anchorEl?: HTMLElement | null;
  anchorPosition?: { left: number; top: number; height: number };
  initialAnchorOrigin?: PopoverOrigin;
  initialTransformOrigin?: PopoverOrigin;
  initialPaperWidth: number;
  initialPaperHeight: number;
  marginThreshold?: number;
  open: boolean;
  anchorSize?: { width: number; height: number };
}

const minPaperWidth = 80;
const minPaperHeight = 120;

function getOffsetLeft(
  rect: {
    height: number;
    width: number;
  },
  paperWidth: number,
  horizontal: number | 'center' | 'left' | 'right',
  transformHorizontal: number | 'center' | 'left' | 'right'
) {
  let offset = 0;

  if (typeof horizontal === 'number') {
    offset = horizontal;
  } else if (horizontal === 'center') {
    offset = rect.width / 2;
  } else if (horizontal === 'right') {
    offset = rect.width;
  }

  if (transformHorizontal === 'center') {
    offset -= paperWidth / 2;
  } else if (transformHorizontal === 'right') {
    offset -= paperWidth;
  }

  return offset;
}

function getOffsetTop(
  rect: {
    height: number;
    width: number;
  },
  papertHeight: number,
  vertical: number | 'center' | 'bottom' | 'top',
  transformVertical: number | 'center' | 'bottom' | 'top'
) {
  let offset = 0;

  if (typeof vertical === 'number') {
    offset = vertical;
  } else if (vertical === 'center') {
    offset = rect.height / 2;
  } else if (vertical === 'bottom') {
    offset = rect.height;
  }

  if (transformVertical === 'center') {
    offset -= papertHeight / 2;
  } else if (transformVertical === 'bottom') {
    offset -= papertHeight;
  }

  return offset;
}

const defaultAnchorOrigin: PopoverOrigin = {
  vertical: 'top',
  horizontal: 'left',
};

const defaultTransformOrigin: PopoverOrigin = {
  vertical: 'top',
  horizontal: 'left',
};

const usePopoverAutoPosition = ({
  anchorEl,
  anchorPosition,
  initialAnchorOrigin = defaultAnchorOrigin,
  initialTransformOrigin = defaultTransformOrigin,
  initialPaperWidth,
  initialPaperHeight,
  marginThreshold = 16,
  open,
}: UsePopoverAutoPositionProps): PopoverPosition & {
  calculateAnchorSize: () => void;
} => {
  const [position, setPosition] = useState<PopoverPosition>({
    anchorOrigin: initialAnchorOrigin,
    transformOrigin: initialTransformOrigin,
    paperWidth: initialPaperWidth,
    paperHeight: initialPaperHeight,
    anchorPosition,
    isEntered: false,
  });

  const calculateAnchorSize = useCallback(() => {
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;

    const getAnchorOffset = () => {
      if (anchorPosition) {
        return {
          ...anchorPosition,
          width: 0,
        };
      }

      return anchorEl ? anchorEl.getBoundingClientRect() : undefined;
    };

    const anchorRect = getAnchorOffset();

    if (!anchorRect) return;
    let newPaperWidth = initialPaperWidth;
    let newPaperHeight = initialPaperHeight;
    const newAnchorPosition = {
      top: anchorRect.top,
      left: anchorRect.left,
    };

    // calculate new paper width
    const newLeft =
      anchorRect.left +
      getOffsetLeft(anchorRect, newPaperWidth, initialAnchorOrigin.horizontal, initialTransformOrigin.horizontal);
    const newTop =
      anchorRect.top +
      getOffsetTop(anchorRect, newPaperHeight, initialAnchorOrigin.vertical, initialTransformOrigin.vertical);

    let isExceedViewportRight = false;
    let isExceedViewportBottom = false;
    let isExceedViewportLeft = false;
    let isExceedViewportTop = false;

    // Check if exceed viewport right
    if (newLeft + newPaperWidth > viewportWidth - marginThreshold) {
      isExceedViewportRight = true;
      // Check if exceed viewport left
      if (newLeft - newPaperWidth < marginThreshold) {
        isExceedViewportLeft = true;
        newPaperWidth = Math.max(minPaperWidth, Math.min(newPaperWidth, viewportWidth - newLeft - marginThreshold));
      }
    }

    // Check if exceed viewport bottom
    if (newTop + newPaperHeight > viewportHeight - marginThreshold) {
      isExceedViewportBottom = true;
      // Check if exceed viewport top
      if (newTop - newPaperHeight < marginThreshold) {
        isExceedViewportTop = true;
        newPaperHeight = Math.max(minPaperHeight, Math.min(newPaperHeight, viewportHeight - newTop - marginThreshold));
      }
    }

    const newPosition = {
      anchorOrigin: { ...initialAnchorOrigin },
      transformOrigin: { ...initialTransformOrigin },
      paperWidth: newPaperWidth,
      paperHeight: newPaperHeight,
      anchorPosition: newAnchorPosition,
    };

    // If exceed viewport, adjust anchor origin and transform origin
    if (!isExceedViewportRight && !isExceedViewportLeft) {
      if (isExceedViewportBottom && !isExceedViewportTop) {
        newPosition.anchorOrigin.vertical = 'top';
        newPosition.transformOrigin.vertical = 'bottom';
      } else if (!isExceedViewportBottom && isExceedViewportTop) {
        newPosition.anchorOrigin.vertical = 'bottom';
        newPosition.transformOrigin.vertical = 'top';
      }
    } else if (!isExceedViewportBottom && !isExceedViewportTop) {
      if (isExceedViewportRight && !isExceedViewportLeft) {
        newPosition.anchorOrigin.horizontal = 'left';
        newPosition.transformOrigin.horizontal = 'right';
      } else if (!isExceedViewportRight && isExceedViewportLeft) {
        newPosition.anchorOrigin.horizontal = 'right';
        newPosition.transformOrigin.horizontal = 'left';
      }
    }

    // anchorPosition is top-left of the anchor element, so we need to adjust it to avoid overlap with the anchor element
    if (newPosition.anchorOrigin.vertical === 'bottom' && newPosition.transformOrigin.vertical === 'top') {
      newPosition.anchorPosition.top += anchorRect.height;
    }

    if (
      isExceedViewportTop &&
      isExceedViewportBottom &&
      newPosition.anchorOrigin.vertical === 'top' &&
      newPosition.transformOrigin.vertical === 'bottom'
    ) {
      newPosition.paperHeight = newPaperHeight - anchorRect.height;
    }

    // Set new position and set isEntered to true
    setPosition({ ...newPosition, isEntered: true });
  }, [
    initialAnchorOrigin,
    initialTransformOrigin,
    initialPaperWidth,
    initialPaperHeight,
    marginThreshold,
    anchorEl,
    anchorPosition,
  ]);

  useEffect(() => {
    if (!open) return;
    calculateAnchorSize();
  }, [open, calculateAnchorSize]);

  return {
    ...position,
    calculateAnchorSize,
  };
};

export default usePopoverAutoPosition;
