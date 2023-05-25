import { useDocument } from './DocumentPage.hooks';
import { createTheme, ThemeProvider } from '@mui/material';
import Root from '../components/document/Root';
import { DocumentControllerContext } from '../stores/effects/document/document_controller';

const muiTheme = createTheme({
  typography: {
    fontFamily: ['Poppins'].join(','),
    fontSize: 14,
  },
  palette: {
    primary: {
      main: '#00BCF0',
    },
  },
});

export const DocumentPage = () => {
  const { documentId, documentData, controller } = useDocument();

  if (!documentId || !documentData || !controller) return null;
  return (
    <ThemeProvider theme={muiTheme}>
      <DocumentControllerContext.Provider value={controller}>
        <Root documentData={documentData} />
      </DocumentControllerContext.Provider>
    </ThemeProvider>
  );
};
