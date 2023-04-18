import { toggleFormat, isFormatActive } from '$app/utils/slate/format';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';

import { command } from '$app/constants/toolbar';
import FormatIcon from './FormatIcon';
import { BaseEditor } from 'slate';

const FormatButton = ({ editor, format, icon }: { editor: BaseEditor; format: string; icon: string }) => {
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
        <FormatIcon icon={icon} />
      </IconButton>
    </Tooltip>
  );
};

export default FormatButton;
