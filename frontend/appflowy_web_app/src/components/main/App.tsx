import { AUTH_CALLBACK_PATH } from '@/application/session/sign_in';
import NotFound from '@/components/error/NotFound';
import LoginAuth from '@/components/login/LoginAuth';
import AcceptInvitationPage from '@/pages/AcceptInvitationPage';
import AfterPaymentPage from '@/pages/AfterPaymentPage';
import AsTemplatePage from '@/pages/AsTemplatePage';
import LoginPage from '@/pages/LoginPage';
import PublishPage from '@/pages/PublishPage';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import withAppWrapper from '@/components/main/withAppWrapper';
import '@/styles/app.scss';

const AppMain = withAppWrapper(() => {
  return (
    <Routes>
      <Route path={'/:namespace/:publishName'} element={<PublishPage />} />
      <Route path={'/login'} element={<LoginPage />} />
      <Route path={AUTH_CALLBACK_PATH} element={<LoginAuth />} />
      <Route path="/404" element={<NotFound />} />
      <Route path="/after-payment" element={<AfterPaymentPage />} />
      <Route path="/as-template" element={<AsTemplatePage />} />
      <Route path="/accept-invitation" element={<AcceptInvitationPage />} />
      <Route path="*" element={<NotFound />} />
    </Routes>
  );
});

function App () {
  return (
    <BrowserRouter>
      <AppMain />
    </BrowserRouter>
  );
}

export default App;
