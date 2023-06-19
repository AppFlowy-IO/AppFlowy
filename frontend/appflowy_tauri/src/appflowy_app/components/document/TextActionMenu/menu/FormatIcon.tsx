import React from 'react';
import { FormatBold, FormatUnderlined, FormatItalic, CodeOutlined, StrikethroughSOutlined } from '@mui/icons-material';
import { TextAction } from '$app/interfaces/document';
import LinkIcon from '@mui/icons-material/AddLink';
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
    case TextAction.Link:
      return (
        <div className={'flex items-center justify-center px-1 text-[0.8rem]'}>
          <LinkIcon
            sx={{
              fontSize: '1.2rem',
              marginRight: '0.25rem',
            }}
          />
          <div className={'underline'}>Link</div>
        </div>
      );
    default:
      return null;
  }
}
