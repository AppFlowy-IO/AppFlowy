import React from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import ImageEdit from './ImageEdit';

interface Props extends PopoverProps {
  onSubmitUrl: (url: string) => void;
  url?: string;
}

function ImageEditPopover({ onSubmitUrl, url, ...props }: Props) {
  return (
    <Popover {...props}>
      <ImageEdit onSubmitUrl={onSubmitUrl} url={url} />
    </Popover>
  );
}

export default ImageEditPopover;
