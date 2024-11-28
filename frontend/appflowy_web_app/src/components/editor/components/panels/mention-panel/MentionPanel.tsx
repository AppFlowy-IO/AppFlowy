import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { MentionType, View, ViewLayout } from '@/application/types';
import { flattenViews } from '@/components/_shared/outline/utils';
import { ViewIcon } from '@/components/_shared/view-icon';
import { usePanelContext } from '@/components/editor/components/panels/Panels.hooks';
import { PanelType } from '@/components/editor/components/panels/PanelsContext';
import { useEditorContext } from '@/components/editor/EditorContext';
import { isFlagEmoji } from '@/utils/emoji';
import { Button, Divider } from '@mui/material';
import { sortBy, uniqBy } from 'lodash-es';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Transforms } from 'slate';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { ReactComponent as ArrowIcon } from '@/assets/north_east.svg';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';
import { Popover } from '@/components/_shared/popover';

enum MentionTag {
  Reminer = 'reminder',
  User = 'user',
  Page = 'page',
  NewPage = 'newPage',
}

interface Option {
  category: MentionTag;
  index: number;
}

export function MentionPanel () {
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
    addPage,
    openPageModal,
  } = useEditorContext();
  const { t } = useTranslation();
  const ref = useRef<HTMLDivElement>(null);
  const open = useMemo(() => {
    return isPanelOpen(PanelType.Mention) || isPanelOpen(PanelType.PageReference);
  }, [isPanelOpen]);
  const selectedOptionRef = React.useRef<Option | null>(null);
  const [selectedOption, setSelectedOption] = React.useState<Option | null>(null);
  const editor = useSlateStatic() as YjsEditor;
  const [moreCount, setMoreCount] = useState<number>(5);
  const [views, setViews] = useState<View[]>([]);

  useEffect(() => {
    if (!open) {
      selectedOptionRef.current = null;
      setSelectedOption(null);
      setMoreCount(5);
    }
  }, [open]);

  useEffect(() => {
    if (!open || !loadViews) return;

    void (async () => {
      try {
        const views = await loadViews();
        const result = sortBy(uniqBy(flattenViews(views || []), 'view_id'), 'last_edited_time').reverse();

        setViews(result);
      } catch (e) {
        console.error(e);
      }

    })();
  }, [loadViews, open]);

  const filteredViews = useMemo(() => {
    return views.filter(view => {
      if (view.view_id === viewId) return false;
      if (!searchText) return true;
      return view.name.toLowerCase().includes(searchText.toLowerCase());
    });
  }, [searchText, viewId, views]);

  const splicedViews = useMemo(() => {
    return filteredViews.slice(0, moreCount);
  }, [filteredViews, moreCount]);

  const showMore = moreCount < filteredViews.length;
  const handleClickMore = useCallback(() => {
    setMoreCount(moreCount + 5);
  }, [moreCount]);

  useEffect(() => {
    selectedOptionRef.current = selectedOption;
    if (!selectedOption) return;
    const {
      category,
      index,
    } = selectedOption;
    const el = ref.current?.querySelector(`[data-option-category="${category}"] [data-option-index="${index}"]`) as HTMLButtonElement | null;

    el?.scrollIntoView({
      behavior: 'smooth',
      block: 'nearest',
    });
  }, [selectedOption]);

  const handleSelectedPage = useCallback((viewId: string, type = MentionType.PageRef) => {
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

  const handleAddPage = useCallback(async (type = MentionType.PageRef) => {
    if (!addPage || !viewId) return;
    try {
      const newViewId = await addPage(viewId, { name: searchText, layout: ViewLayout.Document });

      handleSelectedPage(newViewId, type);
      openPageModal?.(newViewId);
    } catch (e) {
      console.error(e);
    }
  }, [addPage, searchText, handleSelectedPage, viewId, openPageModal]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!open) return;
      const { key } = e;

      switch (key) {
        case 'Enter':
          e.preventDefault();
          if (selectedOptionRef.current) {
            const index = selectedOptionRef.current.index;

            if (selectedOptionRef.current.category === MentionTag.NewPage) {
              void handleAddPage(index === 0 ? MentionType.childPage : MentionType.PageRef);
            } else {
              const viewId = splicedViews[index].view_id;

              handleSelectedPage(viewId, MentionType.PageRef);
            }
          }

          break;
        case 'ArrowUp':
        case 'ArrowDown': {
          e.stopPropagation();
          e.preventDefault();
          if (!selectedOptionRef.current) {
            e.key === 'ArrowDown' ? setSelectedOption({
              category: MentionTag.Page,
              index: 0,
            }) : setSelectedOption({
              category: MentionTag.NewPage,
              index: 1,
            });
            break;
          }

          const { category, index } = selectedOptionRef.current;

          if (category === MentionTag.Page) {
            if (index === 0 && e.key === 'ArrowUp') {
              setSelectedOption({
                category: MentionTag.NewPage,
                index: 1,
              });
              break;
            } else if (index === splicedViews.length - 1 && e.key === 'ArrowDown') {
              setSelectedOption({
                category: MentionTag.NewPage,
                index: 0,
              });
              break;
            } else {
              const nextIndex = e.key === 'ArrowDown' ? (index + 1) % splicedViews.length : (index - 1 + splicedViews.length) % splicedViews.length;

              setSelectedOption({
                category: MentionTag.Page,
                index: nextIndex,
              });
              break;
            }
          }

          if (category === MentionTag.NewPage) {
            if (index === 0 && e.key === 'ArrowUp') {
              setSelectedOption({
                category: MentionTag.Page,
                index: splicedViews.length - 1,
              });
              break;
            } else if (index === 1 && e.key === 'ArrowDown') {
              setSelectedOption({
                category: MentionTag.Page,
                index: 0,
              });
              break;
            } else {
              setSelectedOption({
                category: MentionTag.NewPage,
                index: index === 0 ? 1 : 0,
              });
              break;
            }
          }

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
  }, [closePanel, editor, open, splicedViews, handleSelectedPage, handleAddPage]);

  return (
    <Popover
      adjustOrigins={true}
      data-testid={'mention-panel'}
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
        className={'flex relative w-[320px] flex-col gap-2 max-h-[560px] p-2 appflowy-scroller overflow-y-auto'}
      >
        <div className={'text-text-caption scroll-my-10 px-1'}>{t('inlineActions.recentPages')}</div>
        <div
          data-option-category={MentionTag.Page}
          className={'flex flex-col gap-2'}
        >
          {splicedViews && splicedViews.length > 0 ? (
              <div className={'flex w-full flex-col gap-2'}>
                {splicedViews.map((view, index) => (
                  <Button
                    color={'inherit'}
                    size={'small'}
                    key={view.view_id}
                    data-option-index={index}
                    startIcon={
                      <span className={`${view.icon && isFlagEmoji(view.icon.value) ? 'icon' : ''} flex h-5 w-5 min-w-5 items-center justify-center`}>
                {view.icon?.value || <ViewIcon
                  layout={view.layout}
                  size={'small'}
                />}
              </span>}
                    className={`justify-start truncate scroll-m-2 min-h-[32px] hover:bg-content-blue-50 ${selectedOption?.index === index && selectedOption?.category === MentionTag.Page ? 'bg-fill-list-hover' : ''}`}
                    onClick={() => handleSelectedPage(view.view_id)}
                  >
                    {view.name || t('menuAppHeader.defaultNewPageName')}
                  </Button>
                ))}
              </div>
            ) :
            <div className={'text-text-caption text-sm flex justify-center items-center p-2'}>{t('findAndReplace.noResult')}</div>
          }
          {showMore &&
            <Button
              color={'inherit'}
              size={'small'}
              startIcon={<MoreIcon />}
              className={'justify-start scroll-m-2 min-h-[32px] hover:bg-fill-list-hover'}
              onClick={handleClickMore}
            >
              {filteredViews.length - moreCount} {t('web.moreOptions')}
            </Button>}
        </div>
        <div
          data-option-category={MentionTag.NewPage}
          className={'flex w-full flex-col gap-2'}
        >
          <Divider />
          <Button
            color={'inherit'}
            startIcon={<AddIcon />}
            size={'small'}
            data-option-index={0}
            className={`justify-start scroll-m-2 min-h-[32px] hover:bg-fill-list-hover ${selectedOption?.index === 0 && selectedOption?.category === MentionTag.NewPage ? 'bg-fill-list-hover' : ''}`}
            onClick={() => {
              setSelectedOption({
                category: MentionTag.NewPage,
                index: 0,
              });
              void handleAddPage(MentionType.childPage);
            }}
          >
            <span>{t('button.create')}</span>
            <span className={'mx-1'}>{searchText ? `"${searchText}"` : 'new'}</span>
            <span>{t('document.slashMenu.subPage.keyword1')}</span>
          </Button>

          <Button
            color={'inherit'}
            startIcon={<ArrowIcon className={' text-content-blue-900 w-[0.75em] h-[0.75em] mx-0.5'} />}
            size={'small'}
            data-option-index={1}
            className={`justify-start scroll-m-2 min-h-[32px] hover:bg-fill-list-hover ${selectedOption?.index === 1 && selectedOption?.category === MentionTag.NewPage ? 'bg-fill-list-hover' : ''}`}
            onClick={() => {
              setSelectedOption({
                category: MentionTag.NewPage,
                index: 1,
              });
              void handleAddPage(MentionType.PageRef);
            }}
          >
            <span>{t('button.create')}</span>
            <span className={'mx-1'}>{searchText ? `"${searchText}"` : 'new'}</span>
            <span>page in...</span>
          </Button>
        </div>
      </div>
    </Popover>
  );
}

export default MentionPanel;