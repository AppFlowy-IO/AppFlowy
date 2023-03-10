import { useDocument } from './DocumentPage.hooks';
import BlockList from '../components/block/BlockList';
import { BlockContext } from '../utils/block_context';
import { createTheme, ThemeProvider } from '@mui/material';

const theme = createTheme({
  typography: {
    fontFamily: ['Poppins'].join(','),
  },
});
export const DocumentPage = () => {
  const { blocksMap, blockId } = useDocument();

  return (
    <ThemeProvider theme={theme}>
      <div id='appflowy-block-doc' className='flex flex-col items-center'>
        <BlockContext.Provider
          value={{
            id: blockId,
            blocksMap,
          }}
        >
          <BlockList />
        </BlockContext.Provider>
      </div>
    </ThemeProvider>
  );
};
