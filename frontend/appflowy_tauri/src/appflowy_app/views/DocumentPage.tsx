import { useDocument } from './DocumentPage.hooks';
import BlockList from '../components/block/BlockList';
import { BlockContext } from '../utils/block';
import { createTheme, ThemeProvider } from '@mui/material';

const theme = createTheme({
  typography: {
    fontFamily: ['Poppins'].join(','),
  },
});
export const DocumentPage = () => {
  const { blockId, blockEditor } = useDocument();

  if (!blockId || !blockEditor) return <div className='error-page'></div>;
  return (
    <ThemeProvider theme={theme}>
      <div id='appflowy-block-doc' className='doc-scroller-container flex h-[100%] flex-col items-center overflow-auto'>
        <BlockContext.Provider
          value={{
            id: blockId,
            blockEditor,
          }}
        >
          <BlockList blockEditor={blockEditor} blockId={blockId} />
        </BlockContext.Provider>
      </div>
    </ThemeProvider>
  );
};
