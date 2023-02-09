import { AppflowyLogo } from '../../_shared/svg/AppflowyLogo';
import { EyeClosed } from '../../_shared/svg/EyeClosedSvg';
import { EyeOpened } from '../../_shared/svg/EyeOpenSvg';
import { useLogin } from './Login.hooks';

export const Login = () => {
  const { showPassword, onTogglePassword } = useLogin();

  return (
    <form onSubmit={(e) => e.preventDefault()} method='POST'>
      <div className='flex h-screen w-full flex-col items-center justify-center gap-12 text-center'>
        <div className='flex h-10 w-10 justify-center'>
          <AppflowyLogo />
        </div>

        <div>
          <span className='text-2xl font-semibold leading-9'>Login to Appflowy</span>
        </div>

        <div className='flex w-full max-w-[340px]  flex-col gap-6 '>
          <input type='text' className='input w-full' placeholder='Phone / Email' />
          <div className='relative w-full'>
            <input type={showPassword ? 'text' : 'password'} className='input w-full  !pr-10' placeholder='Password' />

            {/* Show password button */}
            <button
              type='button'
              className='absolute right-0 top-0 flex h-full w-12 items-center justify-center '
              onClick={onTogglePassword}
            >
              {showPassword ? <EyeClosed /> : <EyeOpened />}
            </button>
          </div>

          <div className='flex justify-center'>
            {/* Forget password link */}
            <a href='#' className='text-xs text-main-accent hover:text-main-hovered'>
              Forgot password?
            </a>
          </div>
        </div>

        <div className='flex w-full max-w-[340px] flex-col gap-6 '>
          <button type='submit' className='btn btn-primary w-full   !border-0'>
            Login
          </button>

          {/* signup link */}
          <div className='flex justify-center'>
            <span className='text-xs text-gray-400'>
              Don't have an account?
              <a href='/auth/signUp' className='text-main-accent hover:text-main-hovered'>
                <span> Sign up</span>
              </a>
            </span>
          </div>
        </div>
      </div>
    </form>
  );
};
