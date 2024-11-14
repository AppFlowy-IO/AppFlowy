import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { MentionType, View } from '@/application/types';
import { flattenViews } from '@/components/_shared/outline/utils';
import { Popover } from '@/components/_shared/popover';
import { ViewIcon } from '@/components/_shared/view-icon';
import NewPage from '@/components/editor/components/panels/page-reference-panel/NewPage';
import { usePanelContext } from '@/components/editor/components/panels/Panels.hooks';
import { PanelType } from '@/components/editor/components/panels/PanelsContext';
import { useEditorContext } from '@/components/editor/EditorContext';
import { isFlagEmoji } from '@/utils/emoji';
import { Button } from '@mui/material';
import { uniqBy } from 'lodash-es';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Transforms } from 'slate';
import { ReactEditor, useSlateStatic } from 'slate-react';

export function PageReferencePanel () {
  const {
    isPanelOpen,
    panelPosition,
    closePanel,
    searchText,
    removeContent,
  } = usePanelContext();
  const {
    viewId,
    loadViews,
  } = useEditorContext();
  const { t } = useTranslation();
  const ref = useRef<HTMLDivElement>(null);
  const open = useMemo(() => {
    return isPanelOpen(PanelType.PageReference);
  }, [isPanelOpen]);
  const editor = useSlateStatic() as YjsEditor;
  const [selectedViewId, setSelectedViewId] = useState<string | null>(null);
  const [views, setViews] = useState<View[]>([]);
  const selectedOptionRef = React.useRef<string | null>(null);

  const filteredViews = useMemo(() => {
    return views.filter(view => {
      if (view.view_id === viewId) return false;
      if (!searchText) return true;
      return view.name.toLowerCase().includes(searchText.toLowerCase());
    });
  }, [searchText, viewId, views]);

  useEffect(() => {
    selectedOptionRef.current = selectedViewId;
    const el = ref.current?.querySelector(`[data-option-key="${selectedViewId}"]`) as HTMLButtonElement | null;

    el?.scrollIntoView({
      behavior: 'smooth',
      block: 'nearest',
    });
  }, [selectedViewId]);

  const handleClick = useCallback((viewId: string, type = MentionType.PageRef) => {
    setSelectedViewId(viewId);
    removeContent();
    closePanel();
    editor.flushLocalChanges();

    editor.insertText('@');

    const newSelection = editor.selection;

    if (!newSelection) {
      console.error('newSelection is undefined');
      return;
    }

    const start = {
      path: newSelection.anchor.path,
      offset: newSelection.anchor.offset - 1,
    };

    Transforms.select(editor, {
      anchor: start,
      focus: newSelection.focus,
    });
    CustomEditor.addMark(editor, {
      key: EditorMarkFormat.Mention,
      value: {
        page_id: viewId,
        type,
      },
    });

    Transforms.collapse(editor, {
      edge: 'end',
    });
  }, [closePanel, removeContent, editor]);

  useEffect(() => {
    if (!open || !loadViews) return;

    void (async () => {
      try {
        const views = await loadViews();
        const result = uniqBy(flattenViews(views || []), 'view_id');

        if (result.length > 0) {
          setSelectedViewId(result[0].view_id);
        }

        setViews(result);
      } catch (e) {
        console.error(e);
      }

    })();
  }, [loadViews, open]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!open) return;
      const { key } = e;

      switch (key) {
        case 'Enter':
          e.preventDefault();
          if (selectedOptionRef.current) {
            handleClick(selectedOptionRef.current);
          }

          break;
        case 'ArrowUp':
        case 'ArrowDown': {
          e.stopPropagation();
          e.preventDefault();
          const index = filteredViews.findIndex((option) => option.view_id === selectedOptionRef.current);
          const nextIndex = key === 'ArrowDown' ? (index + 1) % filteredViews.length : (index - 1 + filteredViews.length) % filteredViews.length;

          setSelectedViewId(filteredViews[nextIndex].view_id);
          break;
        }

        default:
          break;
      }

    };

    const slateDom = ReactEditor.toDOMNode(editor, editor);

    slateDom.addEventListener('keydown', handleKeyDown);

    return () => {
      slateDom.removeEventListener('keydown', handleKeyDown);
    };
  }, [closePanel, editor, open, filteredViews, handleClick]);

  useEffect(() => {
    if (filteredViews.length > 0) return;
    setSelectedViewId(null);
  }, [filteredViews.length]);

  return (
    <Popover
      data-testid={'page-reference-panel'}
      open={open}
      onClose={closePanel}
      anchorReference={'anchorPosition'}
      anchorPosition={panelPosition}
      disableAutoFocus={true}
      disableRestoreFocus={true}
      disableEnforceFocus={true}
      transformOrigin={{
        vertical: -32,
        horizontal: -8,
      }}
      onMouseDown={e => e.preventDefault()}
    >
      <div
        ref={ref}
        className={'flex relative w-[320px] flex-col gap-2 max-h-[560px] p-2'}
      >
        <div className={'text-text-caption'}>{t('inlineActions.pageReference')}</div>
        <div className={'flex-1 overflow-hidden appflowy-scroller overflow-y-auto'}>
          {filteredViews && filteredViews.length > 0 ? (
              <div className={'flex w-full overflow-hidden flex-col gap-2'}>
                {filteredViews.map((view, index) => (
                  <Button
                    color={'inherit'}
                    size={'small'}
                    key={view.view_id}
                    data-option-key={view.view_id}
                    startIcon={
                      <span className={`${view.icon && isFlagEmoji(view.icon.value) ? 'icon' : ''} flex h-5 w-5 min-w-5 items-center justify-center`}>
                {view.icon?.value || <ViewIcon
                  layout={view.layout}
                  size={'small'}
                />}
              </span>}
                    className={`justify-start truncate scroll-m-2 min-h-[32px] ${index === 0 ? 'scroll-my-10' : ''} hover:bg-content-blue-50 ${selectedViewId === view.view_id ? 'bg-fill-list-hover' : ''}`}
                    onClick={() => handleClick(view.view_id)}
                  >
                    {view.name || t('menuAppHeader.defaultNewPageName')}
                  </Button>
                ))}
              </div>
            ) :
            <div className={'text-text-caption text-sm flex justify-center items-center p-2'}>{t('findAndReplace.noResult')}</div>
          }
        </div>

        <NewPage
          name={searchText || ''}
          onDone={handleClick}
        />
      </div>
    </Popover>
  );
}

export default PageReferencePanel;