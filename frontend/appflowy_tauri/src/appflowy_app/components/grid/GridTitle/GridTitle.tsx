import { useGridTitleHooks } from './GridTitle.hooks';

export const GridTitle = () => {
  const { title, onTitleBlur, onTitleChange } = useGridTitleHooks();

  return (
    <textarea
      className='text-xl font-semibold resize-none w-full h-10 border-0 outline-none'
      rows={1}
      onBlur={onTitleBlur}
      value={title}
      onChange={onTitleChange}
    />
  );
};
