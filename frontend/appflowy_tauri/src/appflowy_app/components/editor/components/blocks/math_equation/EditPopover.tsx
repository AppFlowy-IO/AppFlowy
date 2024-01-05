import React, { useCallback, useState } from 'react';
import Popover from '@mui/material/Popover';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import { TextareaAutosize } from '@mui/material';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { CustomEditor } from '$app/components/editor/command';
import { Element } from 'slate';
import { KeyboardReturnOutlined } from '@mui/icons-material';
import { ReactEditor, useSlateStatic } from 'slate-react';

function EditPopover({
  open,
  anchorEl,
  onClose,
  node,
}: {
  open: boolean;
  node: Element | null;
  anchorEl: HTMLDivElement | null;
  onClose: () => void;
}) {
  const editor = useSlateStatic();

  const { t } = useTranslation();
  const [value, setValue] = useState<string>('');
  const onInput = (event: React.FormEvent<HTMLTextAreaElement>) => {
    setValue(event.currentTarget.value);
  };

  const handleClose = useCallback(() => {
    onClose();
    if (!node) return;
    ReactEditor.focus(editor);
    const path = ReactEditor.findPath(editor, node);

    editor.select(path);
  }, [onClose, editor, node]);

  const handleDone = () => {
    if (!node) return;
    CustomEditor.setMathEquationBlockFormula(editor, node, value);
    handleClose();
  };

  const handleEnter = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    const shift = e.shiftKey;

    // If shift is pressed, allow the user to enter a new line, otherwise close the popover
    if (!shift && e.key === 'Enter') {
      e.preventDefault();
      e.stopPropagation();
      handleDone();
    }
  };

  return (
    <Popover
      {...PopoverCommonProps}
      open={open}
      anchorEl={anchorEl}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'center',
      }}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'center',
      }}
      onClose={handleClose}
    >
      <div className={'flex flex-col gap-3 p-4'}>
        <TextareaAutosize
          className='w-full resize-none whitespace-break-spaces break-all rounded border p-2 text-sm'
          autoFocus
          autoCorrect='off'
          value={value}
          minRows={3}
          onInput={onInput}
          onKeyDown={handleEnter}
          placeholder={`|x| = \\begin{cases}             
  x, &\\quad x \\geq 0 \\\\           
 -x, &\\quad x < 0             
\\end{cases}`}
        />
        <Button endIcon={<KeyboardReturnOutlined />} variant={'outlined'} onClick={handleDone}>
          {t('button.done')}
        </Button>
      </div>
    </Popover>
  );
}

export default EditPopover;
