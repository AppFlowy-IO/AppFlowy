import { AppflowyLogo } from '../../_shared/AppflowyLogo';
import { EyeClosed } from '../../_shared/EyeClosedSvg';
import { EyeOpened } from '../../_shared/EyeOpenSvg';
import { useLogin } from './Login.hooks';

export const Login = () => {
  const { showPassword, onTogglePassword } = useLogin();

  return (
    <form onSubmit={(e) => e.preventDefault()} method='POST'>
      <div className='text-center h-screen w-full flex flex-col justify-center items-center gap-12'>
        <div className='flex justify-center'>
          <AppflowyLogo />
        </div>

        <div>
          <span className='text-2xl font-semibold leading-9'>Login to Appflowy</span>
        </div>

        <div className='flex flex-col gap-6  max-w-[340px] w-full '>
          <input type='text' className='input w-full' placeholder='Phone / Email' />
          <div className='w-full relative'>
            <input type={showPassword ? 'text' : 'password'} className='input !pr-10  w-full' placeholder='Password' />

            {/* Show password button */}
            <button
              type='button'
              className='absolute right-0 top-0 h-full w-12 flex justify-center items-center '
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

        <div className='flex flex-col gap-6 max-w-[340px] w-full '>
          <button type='submit' className='w-full btn !border-0   btn-primary'>
            Login
          </button>

          {/* signup link */}
          <div className='flex justify-center'>
            <span className='text-gray-400 text-xs'>
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
