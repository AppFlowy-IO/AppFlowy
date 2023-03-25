import { useDocument } from './DocumentPage.hooks';
import { createTheme, ThemeProvider } from '@mui/material';
import Root from '../components/document/Root';
import { YDocControllerContext } from '../stores/effects/document/document_controller';

const theme = createTheme({
  typography: {
    fontFamily: ['Poppins'].join(','),
  },
});

export const DocumentPage = () => {
  const { documentId, documentData, controller } = useDocument();

  if (!documentId || !documentData || !controller) return null;
  return (
    <ThemeProvider theme={theme}>
      <YDocControllerContext.Provider value={controller}>
        <Root documentData={documentData} />
      </YDocControllerContext.Provider>
    </ThemeProvider>
  );
};
