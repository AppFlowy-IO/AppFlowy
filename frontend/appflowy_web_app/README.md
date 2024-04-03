<div align="center">

  <h1><code>AppFlowy Web Project</code></h1>

<div>Welcome to the AppFlowy Web Project, a robust and versatile platform designed to bring the innovative features of
AppFlowy to the web. This project uniquely supports running as a desktop application via Tauri, and offers web
interfaces powered by WebAssembly (WASM). Dive into an exceptional development experience with high performance and
extensive capabilities.</div>

</div>

## 🐑 Features

- **Cross-Platform Compatibility**: Seamlessly run on desktop environments with Tauri, and on any web browser through
  WASM.
- **High Performance**: Leverage the speed and efficiency of WebAssembly for your web interfaces.
- **Tauri Integration**: Build lightweight, secure, and efficient desktop applications.
- **Flexible Development**: Utilize a wide range of AppFlowy's functionalities in your web or desktop projects.

## 🚀 Getting Started

### 🛠️ Prerequisites

Before you begin, ensure you have the following installed:

- Node.js (v14 or later)
- Rust (latest stable version)
- Tauri prerequisites for your operating system
- PNPM (8.5.0)

### 🏗️ Installation

#### Clone the Repository

   ```bash
   git clone https://github.com/AppFlowy-IO/AppFlowy
  ```

#### 🌐 Install the frontend dependencies:

   ```bash
    cd frontend/appflowy_web_app
    pnpm install
   ```

#### 🖥️ Desktop Application (Tauri) (Optional)

> **Note**: if you want to run the web app in the browser, skip this step

- Follow the instructions [here](https://tauri.app/v1/guides/getting-started/prerequisites/) to install Tauri

##### Windows and Linux Prerequisites

###### Windows only

- Install the Duckscript CLI and vcpkg

   ```bash
     cargo install --force duckscript_cli
     vcpkg integrate install
   ```

###### Linux only

- Install the required dependencies

   ```bash
     sudo apt-get update
     sudo apt-get install -y libgtk-3-dev libwebkit2gtk-4.0-dev libappindicator3-dev librsvg2-dev patchelf
   ```

- **Get error**: failed to run custom build command for librocksdb-sys v6.11.4

   ```bash
     sudo apt install clang
   ```

##### Install Tauri Dependencies

- Install cargo-make

   ```bash
   cargo install --force cargo-make
   ```


- Install AppFlowy dev tools

   ```bash
   # install development tools
   # make sure you are in the root directory of the project
    cd frontend
    cargo make appflowy-tauri-deps-tools
   ```

- Build the service/dependency

   ```bash
    # make sure you are in the root directory of the project
    cd frontend/appflowy_web_app
    mkdir dist
    cd src-tauri
    cargo build
   ```

### 🚀 Running the Application

#### 🌐 Web Application

- Run the web application

   ```bash
   pnpm run dev
   ```
- Open your browser and navigate to `http://localhost:3000`, You can now interact with the AppFlowy web application

#### 🖥️ Desktop Application (Tauri)

**Ensure close web application before running the desktop application**

- Run the desktop application

   ```bash
   pnpm run tauri:dev
   ```
- The AppFlowy desktop application will open, and you can interact with it

### 🛠️ Development

#### How to add or modify i18n keys

- Modify the i18n files in `frontend/resources/translations/en.json` to add or modify i18n keys
- Run the following command to update the i18n keys in the application

   ```bash
   pnpm run sync:i18n
   ```

#### How to modify the theme

Don't modify the theme file in `frontend/appflowy_web_app/src/styles/variables` directly)

- Modify the theme file in `frontend/appflowy_web_app/style-dictionary/tokens/base.json( or dark.json or light.json)` to
  add or modify theme keys
- Run the following command to update the theme in the application

   ```bash
   pnpm run css:variables
   ```

#### How to add or modify the environment variables

- Modify the environment file in `frontend/appflowy_web_app/.env` to add or modify environment variables

#### How to create symlink for the @appflowyinc/client-api-wasm in local development

- Run the following command to create a symlink for the @appflowyinc/client-api-wasm

   ```bash
     # ensure you are in the frontend/appflowy_web_app directory
   
     pnpm run link:client-api $source_path $target_path
  
     # Example
     # pnpm run link:client-api ../../../AppFlowy-Cloud/libs/client-api-wasm/pkg ./node_modules/@appflowyinc/client-api-wasm
   ```

### 📝 About the Project

#### 📁 Directory Structure

- `frontend/appflowy_web_app`: Contains the web application source code
- `frontend/appflowy_web_app/src`: Contains the app entry point and the source code
- `frontend/appflowy_web_app/src/components`: Contains the react components
- `frontend/appflowy_web_app/src/styles`: Contains the styles for the application
- `frontend/appflowy_web_app/src/utils`: Contains the utility functions
- `frontend/appflowy_web_app/src/i18n`: Contains the i18n files
- `frontend/appflowy_web_app/src/assets`: Contains the assets for the application
- `frontend/appflowy_web_app/src/store`: Contains the redux store
- `frontend/appflowy_web_app/src/@types`: Contains the typescript types
- `frontend/appflowy_web_app/src/applications/services`:  Contains the services for the application. In vite.config.ts,
  we have defined the alias for the services directory for different environments(Tauri/Web)
  ```typescript
    resolve: {
      alias: [
        // ...
        {
          find: '$client-services',
          replacement: process.env.TAURI_MODE
            ? `${__dirname}/src/application/services/tauri-services`
            : `${__dirname}/src/application/services/js-services`,
        },
      ]
    }
  ```

### 🧪 Testing

> To be Continued...


