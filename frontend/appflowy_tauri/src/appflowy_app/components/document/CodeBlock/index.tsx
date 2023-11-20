import { BlockType, NestedBlock } from '$app/interfaces/document';
import React from 'react';
import SelectLanguage from './SelectLanguage';
import { useChange } from '$app/components/document/_shared/EditorHooks/useChange';
import { useKeyDown } from './useKeyDown';
import CodeEditor from '$app/components/document/_shared/SlateEditor/CodeEditor';
import { useSelection } from '$app/components/document/_shared/EditorHooks/useSelection';
import { useAppSelector } from '$app/stores/store';
import { ThemeMode } from '$app/interfaces';

export default React.memo(function CodeBlock({
  node,
  placeholder,
  ...props
}: { node: NestedBlock<BlockType.CodeBlock>; placeholder?: string } & React.HTMLAttributes<HTMLDivElement>) {
  const id = node.id;
  const language = node.data.language;
  const onKeyDown = useKeyDown(id);
  const className = props.className ? ` ${props.className}` : '';
  const { value, onChange } = useChange(node);
  const selectionProps = useSelection(id);
  const isDark = useAppSelector((state) => state.currentUser.userSetting.themeMode === ThemeMode.Dark);

  return (
    <div
      {...props}
      className={`my-1 rounded border border-solid border-line-divider bg-content-blue-50 p-6 ${className}`}
    >
      <div className={'mb-2 w-[100%]'}>
        <SelectLanguage id={id} language={language} />
      </div>
      <CodeEditor
        isDark={isDark}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        language={language}
        onKeyDown={onKeyDown}
        {...selectionProps}
      />
    </div>
  );
});
