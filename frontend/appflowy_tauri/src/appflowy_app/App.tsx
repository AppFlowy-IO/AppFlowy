import { Routes, Route, BrowserRouter } from 'react-router-dom';
import { Screen } from './components/layout/Screen';
import { TestColors } from './components/TestColors/TestColors';
import TestApiButton from './components/TestApiButton/TestApiButton';
import { Welcome } from './pages/Welcome';
import { Provider } from 'react-redux';
import { store } from './store';
import { DocumentPage } from './pages/DocumentPage';
import { BoardPage } from './pages/BoardPage';
import { GridPage } from './pages/GridPage';

const App = () => {
  return (
    <BrowserRouter>
      <Provider store={store}>
        <Screen>
          <Routes>
            <Route path={'/page/colors'} element={<TestColors></TestColors>}></Route>
            <Route path={'/page/api-test'} element={<TestApiButton></TestApiButton>}></Route>
            <Route path={'/page/document/:id'} element={<DocumentPage></DocumentPage>} />
            <Route path={'/page/board/:id'} element={<BoardPage></BoardPage>} />
            <Route path={'/page/grid/:id'} element={<GridPage></GridPage>} />
            <Route path={'/'} element={<Welcome></Welcome>}></Route>
            <Route path={'*'}>Not Found</Route>
          </Routes>
        </Screen>
      </Provider>
    </BrowserRouter>
  );
};

export default App;
