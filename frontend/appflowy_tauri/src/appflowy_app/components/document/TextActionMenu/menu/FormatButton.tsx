import { toggleFormat, isFormatActive } from '$app/utils/document/blocks/text/format';
import IconButton from '@mui/material/IconButton';

import FormatIcon from './FormatIcon';
import { BaseEditor } from 'slate';
import React, { useMemo } from 'react';
import { TextAction } from '$app/interfaces/document';
import MenuTooltip from '$app/components/document/TextActionMenu/menu/MenuTooltip';

const FormatButton = ({ editor, format, icon }: { editor: BaseEditor; format: TextAction; icon: string }) => {
  const formatTooltips: Record<string, string> = useMemo(
    () => ({
      [TextAction.Bold]: 'Bold',
      [TextAction.Italic]: 'Italic',
      [TextAction.Underline]: 'Underline',
      [TextAction.Strikethrough]: 'Strike through',
      [TextAction.Code]: 'Make as Code',
    }),
    []
  );

  return (
    <MenuTooltip title={formatTooltips[format]}>
      <IconButton
        size='small'
        sx={{ color: isFormatActive(editor, format) ? '#00BCF0' : 'white' }}
        onClick={() => toggleFormat(editor, format)}
      >
        <FormatIcon icon={icon} />
      </IconButton>
    </MenuTooltip>
  );
};

export default FormatButton;
