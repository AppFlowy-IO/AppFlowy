import ControlsMenu from '@/components/editor/components/toolbar/block-controls/ControlsMenu';
import { useHoverControls } from '@/components/editor/components/toolbar/block-controls/HoverControls.hooks';
import { useEditorContext } from '@/components/editor/EditorContext';
import { IconButton, Tooltip } from '@mui/material';
import React, { useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as AddSvg } from '@/assets/add.svg';
import { ReactComponent as DragSvg } from '@/assets/drag_element.svg';

export function HoverControls () {
  const { setSelectedBlockId } = useEditorContext();
  const [menuAnchorEl, setMenuAnchorEl] = useState<HTMLElement | null>(null);
  const openMenu = Boolean(menuAnchorEl);

  const { ref, cssProperty, onClickAdd, hoveredBlockId } = useHoverControls({
    disabled: openMenu,
  });
  const { t } = useTranslation();

  const onClickOptions = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (!hoveredBlockId) return;
    setMenuAnchorEl(e.currentTarget as HTMLElement);
    setSelectedBlockId?.(hoveredBlockId);
  }, [hoveredBlockId, setSelectedBlockId]);

  return (
    <>
      <div
        ref={ref}
        data-testid={'hover-controls'}
        contentEditable={false}
        // Prevent the toolbar from being selected
        onMouseDown={(e) => {
          e.preventDefault();
        }}
        className={`absolute z-10 gap-1 flex w-[64px] flex-grow transform items-center justify-end px-1 opacity-0 ${cssProperty}`}
      >
        {/* Ensure the toolbar in middle */}
        <div className={`invisible`}>$</div>
        <Tooltip
          title={<div className={'flex flex-col'}>
            <div>{t('blockActions.addBelowTooltip')}</div>
            <div>{`${t('blockActions.addAboveCmd')} ${t('blockActions.addAboveTooltip')}`}</div>
          </div>}
          disableInteractive={true}
        >
          <IconButton
            onClick={onClickAdd}
            size={'small'}
            data-testid={'add-block'}
          >
            <AddSvg />
          </IconButton>
        </Tooltip>
        <Tooltip
          title={<div className={'flex flex-col'}>
            <div>{t('blockActions.openMenuTooltip')}</div>
          </div>}
          disableInteractive={true}
        >
          <IconButton
            data-testid={'open-block-options'}
            onClick={onClickOptions}
            size={'small'}
          >
            <DragSvg />
          </IconButton>
        </Tooltip>
      </div>
      {hoveredBlockId && openMenu && <ControlsMenu
        blockId={hoveredBlockId}
        open={openMenu}
        anchorEl={menuAnchorEl}
        onClose={() => {
          setMenuAnchorEl(null);
        }}
      />}
    </>
  );
}

export default HoverControls;