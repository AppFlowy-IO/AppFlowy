import React, { useCallback, useEffect, useState } from 'react';
import Popover from '@mui/material/Popover';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import { TextareaAutosize } from '@mui/material';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { CustomEditor } from '$app/components/editor/command';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { MathEquationNode } from '$app/application/document/document.types';
import katex from 'katex';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';

const initialOrigin: {
  transformOrigin: PopoverOrigin;
  anchorOrigin: PopoverOrigin;
} = {
  transformOrigin: {
    vertical: 'top',
    horizontal: 'center',
  },
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'center',
  },
};

function EditPopover({
  open,
  anchorEl,
  onClose,
  node,
}: {
  open: boolean;
  node: MathEquationNode;
  anchorEl: HTMLDivElement | null;
  onClose: () => void;
}) {
  const editor = useSlateStatic();

  const [error, setError] = useState<{
    name: string;
    message: string;
  } | null>(null);
  const { t } = useTranslation();
  const [value, setValue] = useState<string>(node.data.formula || '');
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
    if (!node || error) return;
    if (value !== node.data.formula) {
      CustomEditor.setMathEquationBlockFormula(editor, node, value);
    }

    handleClose();
  };

  const onKeyDown = (e: React.KeyboardEvent) => {
    e.stopPropagation();
    const shift = e.shiftKey;

    // If shift is pressed, allow the user to enter a new line, otherwise close the popover
    if (!shift && e.key === 'Enter') {
      e.preventDefault();
      e.stopPropagation();
      handleDone();
    }

    if (e.key === 'Escape') {
      e.preventDefault();
      e.stopPropagation();
      handleClose();
    }
  };

  useEffect(() => {
    try {
      katex.render(value, document.createElement('div'));
      setError(null);
    } catch (e) {
      setError(
        e as {
          name: string;
          message: string;
        }
      );
    }
  }, [value]);

  const { transformOrigin, anchorOrigin, isEntered } = usePopoverAutoPosition({
    initialPaperWidth: 300,
    initialPaperHeight: 170,
    anchorEl,
    initialAnchorOrigin: initialOrigin.anchorOrigin,
    initialTransformOrigin: initialOrigin.transformOrigin,
    open,
  });

  return (
    <Popover
      {...PopoverCommonProps}
      open={open && isEntered}
      anchorEl={anchorEl}
      transformOrigin={transformOrigin}
      anchorOrigin={anchorOrigin}
      onClose={handleClose}
      onMouseDown={(e) => {
        e.stopPropagation();
      }}
      onKeyDown={onKeyDown}
    >
      <div className={'flex flex-col gap-3 p-4'}>
        <TextareaAutosize
          className='w-full resize-none whitespace-break-spaces break-all rounded border p-2 text-sm'
          autoFocus
          autoCorrect='off'
          autoComplete={'off'}
          spellCheck={false}
          value={value}
          minRows={4}
          onInput={onInput}
          onKeyDown={onKeyDown}
          placeholder={`|x| = \\begin{cases}             
  x, &\\quad x \\geq 0 \\\\           
 -x, &\\quad x < 0             
\\end{cases}`}
        />

        {error && (
          <div className={'max-w-[270px] text-xs text-red-500'}>
            {error.name}: {error.message}
          </div>
        )}

        <div className={'flex justify-between gap-2'}>
          <Button
            size={'small'}
            color={'inherit'}
            variant={'outlined'}
            onClick={handleClose}
            className={'flex-grow text-text-caption'}
          >
            {t('button.cancel')}
          </Button>
          <Button disabled={!!error} size={'small'} variant={'contained'} onClick={handleDone} className={'flex-grow'}>
            {t('button.done')}
          </Button>
        </div>
      </div>
    </Popover>
  );
}

export default EditPopover;
