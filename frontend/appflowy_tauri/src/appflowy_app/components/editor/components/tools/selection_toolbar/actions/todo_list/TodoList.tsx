import React, { useCallback } from 'react';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { EditorNodeType } from '$app/application/document/document.types';
import { ReactComponent as TodoListSvg } from '$app/assets/todo-list.svg';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';

export function TodoList() {
  const { t } = useTranslation();
  const editor = useSlateStatic();

  const isActivated = CustomEditor.isBlockActive(editor, EditorNodeType.TodoListBlock);

  const onClick = useCallback(() => {
    CustomEditor.turnToBlock(editor, {
      type: EditorNodeType.TodoListBlock,
    });
  }, [editor]);

  return (
    <ActionButton active={isActivated} onClick={onClick} tooltip={t('document.plugins.todoList')}>
      <TodoListSvg />
    </ActionButton>
  );
}

export default TodoList;
