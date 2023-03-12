import { useSlate } from 'slate-react';
import { toggleFormat, isFormatActive } from '$app/utils/editor/format';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import { useMemo } from 'react';
import { FormatBold, FormatUnderlined, FormatItalic, CodeOutlined, StrikethroughSOutlined } from '@mui/icons-material';
import { command, iconSize } from '$app/constants/toolbar';

const FormatButton = ({ format, icon }: { format: string; icon: string }) => {
  const editor = useSlate();

  const renderComponent = useMemo(() => {
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
        break;
    }
  }, [icon]);

  return (
    <Tooltip
      slotProps={{ tooltip: { style: { background: '#E0F8FF', borderRadius: 8 } } }}
      title={
        <div className='flex flex-col'>
          <span className='text-base font-medium text-black'>{command[format].title}</span>
          <span className='text-sm text-slate-400'>{command[format].key}</span>
        </div>
      }
      placement='top-start'
    >
      <IconButton
        size='small'
        sx={{ color: isFormatActive(editor, format) ? '#00BCF0' : 'white' }}
        onClick={() => toggleFormat(editor, format)}
      >
        {renderComponent}
      </IconButton>
    </Tooltip>
  );
};

export default FormatButton;
