# AppFlowy Web Project

## Installation

```bash
cd appflowy-web

# Install dependencies
rm -rf node_modules && pnpm install
```

## Running the app

```bash
# development
pnpm run dev

# production mode
pnpm run build

# generate wasm
pnpm run wasm
```



## Run tests in Chrome

> Before executing the test, you need to install the [Chrome Driver](https://chromedriver.chromium.org/downloads). If 
> you are using a Mac, you can easily install it using Homebrew.
> 
> ```shell
> brew install chromedriver
> ```


Go to `frontend/appflowy_web/wasm-libs` and run:
```shell
wasm-pack test --chrome
```

Run tests in headless Chrome
```shell
wasm-pack test --headless --chrome
```