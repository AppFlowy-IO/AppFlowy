import { Routes, Route, Link, useParams, BrowserRouter } from 'react-router-dom';
import { Screen } from './components/Screen/application/Screen';
import { TestColors } from './components/TestColors/TestColors';

const App = () => {
  return (
    <BrowserRouter>
      <Screen>
        <Routes>
          <Route path={'/'} element={<TestColors></TestColors>}></Route>
          <Route path={'*'}>Not Found</Route>
        </Routes>
      </Screen>
    </BrowserRouter>
  );
};

export default App;
