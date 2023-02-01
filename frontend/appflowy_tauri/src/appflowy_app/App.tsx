import { Routes, Route, BrowserRouter } from 'react-router-dom';
import { Screen } from './components/layout/Screen';
import { TestColors } from './components/TestColors/TestColors';
import TestApiButton from './components/TestApiButton/TestApiButton';
import { Welcome } from './pages/Welcome';
import { Provider } from 'react-redux';
import { store } from './store';

const App = () => {
  return (
    <BrowserRouter>
      <Provider store={store}>
        <Screen>
          <Routes>
            <Route path={'/page/colors'} element={<TestColors></TestColors>}></Route>
            <Route path={'/page/api-test'} element={<TestApiButton></TestApiButton>}></Route>
            <Route path={'/'} element={<Welcome></Welcome>}></Route>
            <Route path={'*'}>Not Found</Route>
          </Routes>
        </Screen>
      </Provider>
    </BrowserRouter>
  );
};

export default App;
