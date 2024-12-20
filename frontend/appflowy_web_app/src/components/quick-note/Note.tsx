import React, { useCallback, useContext, useEffect, useMemo } from 'react';
import { Editor, EditorData, EditorProvider, useEditor } from '@appflowyinc/editor';
import '@appflowyinc/editor/style';

import { useTranslation } from 'react-i18next';
import { ThemeModeContext } from '@/components/main/useAppThemeMode';
import { useCurrentWorkspaceId } from '@/components/app/app.hooks';
import { useService } from '@/components/main/app.hooks';
import { debounce } from 'lodash-es';
import { QuickNote, QuickNoteEditorData } from '@/application/types';

function Note({
  note,
  onUpdateData,
}: {
  note: QuickNote,
  onUpdateData: (data: QuickNoteEditorData[]) => void;
}) {

  const ref = React.useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;

    if (!el) return;

    setTimeout(() => {
      const editorDom = el.querySelector('.appflowy-editor div[role="textbox"]') as HTMLElement;

      if (!editorDom) return;

      const sel = window.getSelection();
      const range = document.createRange();

      range.selectNodeContents(editorDom);
      range.collapse(true);
      sel?.removeAllRanges();
      sel?.addRange(range);
    }, 200);

    //eslint-disable-next-line
  }, [note.id]);

  return (
    <div ref={ref} className={'flex flex-1 overflow-hidden pb-4'}>
      <EditorProvider>
        <NoteEditor note={note} onUpdateData={onUpdateData}/>
      </EditorProvider>
    </div>
  );
}

function NoteEditor({
  note,
  onUpdateData,
}: {
  note: QuickNote,
  onUpdateData: (data: QuickNoteEditorData[]) => void;
}) {
  const { i18n } = useTranslation();
  const locale = useMemo(() => ({
    lang: i18n.language,
  }), [i18n.language]);

  const isDark = useContext(ThemeModeContext)?.isDark;
  const theme = isDark ? 'dark' : 'light';

  const editor = useEditor();

  useEffect(() => {
    editor.applyData(note.data as EditorData);
    // eslint-disable-next-line
  }, [editor, note.id]);

  const currentWorkspaceId = useCurrentWorkspaceId();
  const service = useService();

  const handleUpdate = useCallback(async (data: EditorData) => {
    if (!service || !currentWorkspaceId) return;
    try {
      await service.updateQuickNote(currentWorkspaceId, note.id, data as QuickNoteEditorData[]);
      // eslint-disable-next-line
    } catch (e: any) {
      console.error(e);
    }
  }, [service, currentWorkspaceId, note.id]);

  const debounceUpdate = useMemo(() => debounce(handleUpdate, 300), [handleUpdate]);

  const handleChange = useCallback((data: EditorData) => {
    void debounceUpdate(data);
    onUpdateData(data as QuickNoteEditorData[]);
  }, [debounceUpdate, onUpdateData]);

  useEffect(() => {
    return () => {
      void debounceUpdate.flush();
    };
  }, [debounceUpdate]);

  return <Editor
    modalZIndex={1500}
    initialValue={note.data as EditorData} locale={locale} onChange={handleChange}
    theme={theme}
  />;
}

export default Note;