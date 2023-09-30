# Build AppFlowy for Debian

## Prerequisites

- dpkg-deb
- make sure you have built the app for Linux which is located in `frontend/appflowy_flutter/production/$VERSION/linux/Release/`

## Build

```bash
cd frontend/
sh scripts/linux_distribution/deb/build_deb.sh [LINUX_PRODUCTION_RELEASE_PATH] [VERSION] [PACKAGE_NAME]

# for example
sh scripts/linux_distribution/deb/build_deb.sh appflowy_flutter/product/0.2.9/linux/Release 0.2.9 AppFlowy_0.2.9.deb
```

The deb file will be located in '[LINUX_PRODUCTION_RELEASE_PATH]/[PACKAGE_NAME]'
