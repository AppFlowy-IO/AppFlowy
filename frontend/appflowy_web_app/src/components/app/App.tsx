import NotFound from '@/components/error/NotFound';
import PublishPage from '@/pages/PublishPage';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import withAppWrapper from '@/components/app/withAppWrapper';
import '@/styles/app.scss';

const AppMain = withAppWrapper(() => {
  return (
    <Routes>
      <Route path={'/:namespace/:publishName'} element={<PublishPage />} />
      <Route path='/404' element={<NotFound />} />
      <Route path='*' element={<NotFound />} />
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
