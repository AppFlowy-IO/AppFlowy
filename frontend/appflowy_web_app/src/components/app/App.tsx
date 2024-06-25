import PublishPage from '@/pages/PublishPage';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import withAppWrapper from '@/components/app/withAppWrapper';
import '@/styles/app.scss';

const AppMain = withAppWrapper(() => {
  return (
    <Routes>
      <Route path={'/:namespace/:publishName'} element={<PublishPage />} />
    </Routes>
  );
});

function App() {
  return (
    <BrowserRouter>
      <AppMain />
    </BrowserRouter>
  );
}

export default App;
