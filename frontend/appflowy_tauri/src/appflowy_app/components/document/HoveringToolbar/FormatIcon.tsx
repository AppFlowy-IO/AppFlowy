import React from 'react';
import { FormatBold, FormatUnderlined, FormatItalic, CodeOutlined, StrikethroughSOutlined } from '@mui/icons-material';
import { iconSize } from '$app/constants/toolbar';

export default function FormatIcon({ icon }: { icon: string }) {
  switch (icon) {
    case 'bold':
      return <FormatBold sx={iconSize} />;
    case 'underlined':
      return <FormatUnderlined sx={iconSize} />;
    case 'italic':
      return <FormatItalic sx={iconSize} />;
    case 'code':
      return <CodeOutlined sx={iconSize} />;
    case 'strikethrough':
      return <StrikethroughSOutlined sx={iconSize} />;
    default:
      return null;
  }
}
