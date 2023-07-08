import { BrowserRouter } from 'react-router-dom';

import { Provider } from 'react-redux';
import { store } from './stores/store';

import { ErrorHandlerPage } from './components/error/ErrorHandlerPage';
import initializeI18n from './stores/i18n/initializeI18n';

import { ErrorBoundary } from 'react-error-boundary';

import AppMain from '$app/AppMain';

initializeI18n();

const App = () => {
  return (
    <BrowserRouter>
      <Provider store={store}>
        <ErrorBoundary FallbackComponent={ErrorHandlerPage}>
          <AppMain />
        </ErrorBoundary>
      </Provider>
    </BrowserRouter>
  );
};

export default App;
