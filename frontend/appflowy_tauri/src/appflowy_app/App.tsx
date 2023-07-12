import { BrowserRouter } from 'react-router-dom';

import { Provider } from 'react-redux';
import { store } from './stores/store';

import { ErrorHandlerPage } from './components/error/ErrorHandlerPage';
import '$app/i18n/config';

import { ErrorBoundary } from 'react-error-boundary';

import AppMain from '$app/AppMain';

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
