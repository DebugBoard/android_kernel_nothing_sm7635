# KernelSU-Next Integration Script

This repository contains a script to automatically integrate KernelSU-Next (and optionally SuSFS) into the Nothing Phone SM7635 kernel.

## Prerequisites

### On Arch Linux, install the required dependencies:

```bash
sudo pacman -S base-devel git bc bison flex zip curl wget python3 clang
```

Optional (if clang is not available):
```bash
sudo pacman -S aarch64-linux-gnu-gcc
```

## Usage

1. **Clone this repository** (if you haven't already):
   ```bash
   git clone <repository-url>
   cd android_kernel_nothing_sm7635
   ```

2. **Run the integration script**:
   ```bash
   ./apply_kernelsu_susfs.sh
   ```

3. **Flash the output**:
   - The script will create a flashable AnyKernel3 zip file named `KernelSU-SuSFS-<timestamp>.zip` in the kernel directory
   - Reboot your device to recovery mode (TWRP/OrangeFox)
   - Flash the generated zip file
   - Reboot to system

## What the Script Does

1. **Dependency Check**: Verifies all required build tools are installed
2. **Clone KernelSU-Next**: Downloads the latest KernelSU-Next from the main branch
3. **Clone SuSFS**: Attempts to download SuSFS (optional, continues without it if unavailable)
4. **Apply Patches**: Integrates KernelSU-Next and SuSFS into the kernel source
5. **Configure Kernel**: Sets up kernel configuration with KernelSU-Next support enabled
6. **Build Kernel**: Compiles the kernel with the new features
7. **Create AK3 Zip**: Packages everything into a flashable AnyKernel3 zip

## Features

- ✅ Automatic dependency checking
- ✅ Error handling and validation
- ✅ Colored output for better readability
- ✅ Support for both Clang and GCC compilers
- ✅ Automatic cleanup of previous builds
- ✅ Parallel compilation using all CPU cores
- ✅ AnyKernel3 packaging for easy flashing

## Configuration

You can modify the following variables at the top of the script if needed:

- `DEFCONFIG`: Default kernel configuration (default: `gki_defconfig`)
- `KERNELSU_BRANCH`: KernelSU-Next branch to use (default: `main`)
- `ARCH`: Target architecture (default: `arm64`)

## Safety Features

The script includes several safety mechanisms:

1. **Exit on error**: The script stops immediately if any command fails
2. **Dependency validation**: Checks all required tools before starting
3. **Dry-run patches**: Tests patches before applying them
4. **Backup recommendations**: Warns users to create backups before flashing

## Troubleshooting

### Build Fails

If the build fails, check:
- All dependencies are installed correctly
- You have enough disk space (at least 20GB recommended)
- Your system has sufficient RAM (8GB+ recommended)

### Missing SuSFS

If SuSFS cannot be cloned (e.g., due to network restrictions):
- The script will continue with KernelSU only
- This is normal and the kernel will still work fine
- You can manually add SuSFS support later if needed

### Compiler Issues

If you encounter compiler errors:
- Try using Clang instead of GCC or vice versa
- Update your compiler to the latest version
- Check the kernel logs for specific error messages

## Important Notes

⚠️ **WARNING**: Flashing a custom kernel can:
- Void your warranty
- Potentially brick your device if done incorrectly
- Cause bootloops if the kernel is incompatible

✅ **ALWAYS**:
- Make a full backup before flashing
- Use recovery mode to flash
- Keep a known-good kernel zip handy
- Test on a non-primary device first if possible

## Support

For issues related to:
- **KernelSU-Next**: Visit [KernelSU-Next GitHub](https://github.com/KernelSU-Next/KernelSU-Next)
- **SuSFS**: Visit [SuSFS GitLab](https://gitlab.com/simonpunk/susfs4ksu)
- **This kernel**: Open an issue in this repository
- **AnyKernel3**: Visit [AnyKernel3 GitHub](https://github.com/osm0sis/AnyKernel3)

## License

This script is provided under GPL-2.0 license, consistent with the Linux kernel.

The kernel source code and KernelSU follow their respective licenses.
