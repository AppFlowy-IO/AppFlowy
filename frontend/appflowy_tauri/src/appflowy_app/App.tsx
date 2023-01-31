import { Routes, Route, Link, useParams, BrowserRouter } from 'react-router-dom';
import { Screen } from './components/Screen/application/Screen';

const App = () => {
  return (
    <BrowserRouter>
      <Screen>
        <Routes>
          <Route path={'/'} element={<div>Home Page</div>}></Route>
          <Route path={'*'}>Not Found</Route>
        </Routes>
      </Screen>
    </BrowserRouter>
  );
};

export default App;
