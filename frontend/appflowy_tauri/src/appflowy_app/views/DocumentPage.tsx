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
      <BlockContext.Provider
        value={{
          id: blockId,
          blockEditor,
        }}
      >
        <BlockList blockEditor={blockEditor} blockId={blockId} />
      </BlockContext.Provider>
    </ThemeProvider>
  );
};
