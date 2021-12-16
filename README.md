<h1 align="center" style="border-bottom: none">
    <b>
        <a href="https://www.appflowy.io">AppFlowy.IO</a><br>
    </b>
    ⭐️ The Open Source Notion Alternative ⭐️ <br>
</h1>


<p align="center">
<a href="https://discord.gg/9Q2xaN37tV"><img src="https://img.shields.io/badge/AppFlowy.IO-discord-orange"></a>
<a href="https://github.com/AppFlowy-IO/appflowy"><img src="https://img.shields.io/github/stars/AppFlowy-IO/appflowy.svg?style=flat&logo=github&colorB=deeppink&label=stars"></a>
<a href="https://github.com/AppFlowy-IO/appflowy"><img src="https://img.shields.io/github/forks/AppFlowy-IO/appflowy.svg"></a>
<a href="https://opensource.org/licenses/AGPL-3.0"><img src="https://img.shields.io/badge/license-AGPL-purple.svg" alt="License: AGPL"></a>

</p>



<p align="center">
You are in charge of your data and customizations.
</p>


<p align="center">
    <a href="http://www.appflowy.io"><b>Website</b></a> •
    <a href="https://discord.gg/9Q2xaN37tV"><b>Discord</b></a> •
    <a href="https://twitter.com/appflowy"><b>Twitter</b></a> •




</p>  

<p align="center"><img src="https://github.com/AppFlowy-IO/appflowy/blob/main/doc/imgs/welcome.png" alt="The Open Source Notion Alternative." width="1000px" /></p>

## Install

### macOS

```sh
brew install appflowy
```

### Windows

There is currently no Windows installer. However, you can download and install the app from the GitHub Releases section.
1. Go to AppFlowy's [Releases](https://github.com/AppFlowy-IO/appflowy/releases/) page on GitHub.
2. Download the current AppFlowy-Windows.zip file
3. Create a directory in your %userprofile%\documents folder
```shell
md %userprofile%\documents\appflowy
```
4. Change to that directory
```shell
cd %userprofile%\documents\appflowy
```
5. Extract the downloaded zip file into the directory you just created.
6. Run the application :
```shell
./app_flowy.exe
```

### Linux

There is currently no Linux installer. However, you can download and install the app from the GitHub Releases section.
1. Go to AppFlowy's [Releases](https://github.com/AppFlowy-IO/appflowy/releases/) page on GitHub.
2. Download the current AppFlowy-Linux.tar.gz file.
3. Create a directory in your /opt/ folder.
```shell
md /opt/appflowy
```
4. Change to that directory
```shell
cd /opt/appflowy
```
5. Extract the downloaded compressed file into the directory you just created.
```shell
tar -xvf AppFlowy-Linux.tar.gz
```
6. Run the application :
```shell
./app_flowy
```

## Built With

* [Flutter](https://flutter.dev/)

* [Rust](https://www.rust-lang.org/)

## Stay Up-to-Date

<p align="center"><img src="https://github.com/AppFlowy-IO/appflowy/blob/main/doc/imgs/howtostar.gif" alt="AppFlowy Github" width="1000px" /></p>

## Getting Started

### Linux
Please follow these instructions to build on [Linux](doc/BUILD_ON_LINUX.md).

### Windows
Please follow these instructions to build on [Windows](doc/BUILD_ON_WINDOWS.md).

### macOS

How to build on MacOS, please follow these simple steps.

**Step 1:**

```shell
git clone https://github.com/AppFlowy-IO/appflowy.git
```

**Step 2:**

```shell
cd appflowy/frontend
```
```shell
make install_rust
```
```shell
source $HOME/.cargo/env
```
```shell
make install_cargo_make
```
```shell
cargo make install_targets
```

>
>
> 🚀 Skip install_rust or install_cargo_make if you already installed it.
> FYI, AppFlowy uses [https://github.com/sagiegurari/cargo-make](https://github.com/sagiegurari/cargo-make) to construct the build scripts

**Step 3:**

Follow the instructions [here](https://flutter.dev/docs/get-started/install) to install Flutter. As AppFlowy uses the `stable` channel, you need to switch the channel. Just type:

```shell
flutter channel stable
```

**Step 4:**

You should enable the specified platform first if you don't enable it before and then select the desktop device.
```shell
# for windows
flutter config --enable-windows-desktop

# for macos
flutter config --enable-macos-desktop

# for linux
flutter config --enable-linux-desktop
```

* Open the `app_flowy` folder located at xx/appflowy/frontend with Visual Studio Code or other IDEs at your disposal.
* Go to the Run and Debug tab and then click the run button.
![Run the project](https://github.com/AppFlowy-IO/appflowy/blob/main/doc/imgs/run.png)

* If you want to build for the other platform, you should modify the build_sdk.sh before running.
![build_sdk](https://user-images.githubusercontent.com/86001920/143262377-bb49e913-10ca-4198-80ec-bd814a13ee1d.png)
Please also check the device selection, AppFlowy only supports Desktop by now:
![device](https://user-images.githubusercontent.com/86001920/144546864-cebbf0c0-4eef-424e-93c7-e1e6b3a59669.png)


* If you encounter any issues, have a look at [Troubleshooting](https://github.com/AppFlowy-IO/appflowy/wiki/Troubleshooting) first. If your issue is not included in the page, please create an [issue](https://github.com/AppFlowy-IO/appflowy/issues/new/choose) or ask on [Discord](https://discord.gg/9Q2xaN37tV).

## Roadmap

[AppFlowy Roadmap](https://trello.com/b/NCyXCXXh/appflowy-roadmap)

If you'd like to propose a feature, submit an issue [here](https://github.com/AppFlowy-IO/appflowy/issues).

## **Releases**

Please see the [changelog](https://www.appflowy.io/whatsnew) for more details about a given release.

## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**. Please look at [CONTRIBUTING.md](https://github.com/AppFlowy-IO/appflowy/blob/main/doc/CONTRIBUTING.md) for details.

## Why Are We Building This?

Notion has been our favorite project and knowledge management tool in recent years because of its aesthetic appeal and functionality. Our team uses it daily, and we are on its paid plan. However, as we all know Notion has its limitations. These include weak data security and poor compatibility with mobile devices. Likewise, alternative collaborative workplace management tools also have their constraints.

The limitations we encountered using these tools rooted in our past work experience with collaborative productivity tools lead to our firm belief that there is, and will be a glass ceiling on what's possible in the future for tools like Notion. This emanates from these tools probable struggles to scale horizontally at some point. It implies that they will likely be forced to prioritize for a proportion of customers whose needs can be quite different from the rest. While decision-makers want a workplace OS, the truth is that it is not very possible to come up with a one-size fits all solution in such a fragmented market.

When a customer's evolving core needs are not satisfied, they either switch to another or build one from the ground up, in-house. Consequently, they either go under another ceiling or buy an expensive ticket to learn a hard lesson. This is a requirement for many resources and expertise, building a reliable and easy-to-use collaborative tool, not to mention the speed and native experience. The same may apply to individual users as well.

All these restrictions necessitate our mission - to make it possible for anyone to create apps that suit their needs well.

- To individuals, we would like to offer Notion's functionality along with data security and cross-platform native experience.
- To enterprises and hackers, AppFlowy is dedicated to offering building blocks, that is, collaboration infra services to enable you to make apps on your own. Moreover, you have 100% control of your data. You can design and modify AppFlowy your way, with a single codebase written in Flutter and Rust supporting multiple platforms armed with long-term maintainability.

We decided to achieve this mission by upholding the three most fundamental values:

- Data privacy first
- Reliable native experience
- Community-driven extensibility

To be honest, we do not claim to outperform Notion in terms of functionality and design, at least for now. Besides, our priority doesn't lie in more functionality at the moment. Instead, we would like to cultivate a community to democratize the knowledge and wheels of making complex workplace management tools, while enabling people and businesses to create beautiful things on their own by equipping them with a versatile toolbox of building blocks.

## License

Distributed under the AGPLv3 License. See `LICENSE.md` for more information.

## Acknowledgements

Special thanks to these amazing projects which help power AppFlowy.IO:

- [flutter-quill](https://github.com/singerdmx/flutter-quill)
