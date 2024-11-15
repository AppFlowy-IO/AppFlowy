import { PopoverOrigin } from '@mui/material/Popover/Popover';
import React, { useState } from 'react';
import { Popover as PopoverComponent, PopoverProps as PopoverComponentProps } from '@mui/material';

const defaultProps: Partial<PopoverComponentProps> = {
  keepMounted: false,
  disableRestoreFocus: true,
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'left',
  },
};

interface Position {
  top: number;
  left: number;
}

export interface Origins {
  anchorOrigin: PopoverOrigin;
  transformOrigin: PopoverOrigin;
}

const DEFAULT_ORIGINS: Origins = {
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'left',
  },
  transformOrigin: {
    vertical: 'top',
    horizontal: 'left',
  },
};

function calculateOptimalOrigins (
  position: Position,
  popoverWidth: number,
  popoverHeight: number,
  defaultOrigins: Origins = DEFAULT_ORIGINS,
  spacing: number = 8,
): Origins {
  const windowWidth = window.innerWidth;
  const windowHeight = window.innerHeight;

  // Check if there is enough space for the default position
  const hasEnoughSpaceForDefault =
    position.top + popoverHeight + spacing <= windowHeight &&
    position.left + popoverWidth + spacing <= windowWidth;

  // If there is enough space for the default position, return it
  if (hasEnoughSpaceForDefault) {
    return defaultOrigins;
  }

  // Otherwise, calculate the optimal position
  const spaceAbove = position.top;
  const spaceBelow = windowHeight - position.top;
  const spaceLeft = position.left;
  const spaceRight = windowWidth - position.left;

  // Vertical
  let vertical: {
    anchor: 'top' | 'center' | 'bottom';
    transform: 'top' | 'center' | 'bottom';
  };

  if (spaceBelow >= popoverHeight + spacing) {
    vertical = { anchor: 'bottom', transform: 'top' };
  } else if (spaceAbove >= popoverHeight + spacing) {
    vertical = { anchor: 'top', transform: 'bottom' };
  } else {
    vertical = spaceBelow > spaceAbove
      ? { anchor: 'center', transform: 'center' }
      : { anchor: 'center', transform: 'center' };
  }

  // Horizontal
  let horizontal: {
    anchor: 'left' | 'center' | 'right';
    transform: 'left' | 'center' | 'right';
  };

  if (spaceRight >= popoverWidth + spacing) {
    horizontal = { anchor: 'left', transform: 'left' };
  } else if (spaceLeft >= popoverWidth + spacing) {
    horizontal = { anchor: 'right', transform: 'right' };
  } else {
    horizontal = spaceRight > spaceLeft
      ? { anchor: 'center', transform: 'center' }
      : { anchor: 'center', transform: 'center' };
  }

  return {
    anchorOrigin: {
      vertical: vertical.anchor,
      horizontal: horizontal.anchor,
    },
    transformOrigin: {
      vertical: vertical.transform,
      horizontal: horizontal.transform,
    },
  };
}

export function Popover ({
  children,
  transformOrigin = DEFAULT_ORIGINS.transformOrigin,
  anchorOrigin = DEFAULT_ORIGINS.anchorOrigin,
  anchorPosition,
  anchorEl,
  adjustOrigins = false,
  ...props
}: PopoverComponentProps & {
  adjustOrigins?: boolean
}) {
  const [origins, setOrigins] = useState<Origins>({
    transformOrigin,
    anchorOrigin,
  });

  const handleEntered = (element: HTMLElement) => {
    const { width, height } = element.getBoundingClientRect();
    let position: Position;

    if (anchorEl && anchorEl instanceof Element) {
      const rect = anchorEl.getBoundingClientRect();

      position = {
        top: rect.top,
        left: rect.left,
      };
    } else if (anchorPosition) {
      position = anchorPosition;
    } else {
      return;
    }

    const newOrigins = calculateOptimalOrigins(
      position,
      width,
      height,
      { anchorOrigin, transformOrigin },
      anchorPosition ? 20 : 8,
    );

    setOrigins(newOrigins);
  };

  return (
    <PopoverComponent
      {...defaultProps}
      {...props}
      anchorEl={anchorEl}
      anchorPosition={anchorPosition}
      TransitionProps={{
        onEntered: adjustOrigins ? handleEntered : undefined,
      }}
      anchorOrigin={origins.anchorOrigin}
      transformOrigin={origins.transformOrigin}
    >
      {children}
    </PopoverComponent>
  );
}

export default Popover;

