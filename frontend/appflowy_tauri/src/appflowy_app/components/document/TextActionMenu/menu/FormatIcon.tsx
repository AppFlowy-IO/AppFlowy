import React from 'react';
import { FormatBold, FormatUnderlined, FormatItalic, CodeOutlined, StrikethroughSOutlined } from '@mui/icons-material';
import { TextAction } from '$app/interfaces/document';
export const iconSize = { width: 18, height: 18 };

export default function FormatIcon({ icon }: { icon: string }) {
  switch (icon) {
    case TextAction.Bold:
      return <FormatBold sx={iconSize} />;
    case TextAction.Underline:
      return <FormatUnderlined sx={iconSize} />;
    case TextAction.Italic:
      return <FormatItalic sx={iconSize} />;
    case TextAction.Code:
      return <CodeOutlined sx={iconSize} />;
    case TextAction.Strikethrough:
      return <StrikethroughSOutlined sx={iconSize} />;
    default:
      return null;
  }
}
