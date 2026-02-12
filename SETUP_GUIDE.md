# KernelSU-Next Integration Setup Guide

This guide explains how to use the KernelSU-Next integration script for the Nothing Phone SM7635 kernel.

## Overview

The `apply_kernelsu_susfs.sh` script automates the process of:
1. Integrating KernelSU-Next into the kernel source
2. Optionally integrating SuSFS for enhanced hiding capabilities
3. Building the kernel with KernelSU-Next support
4. Creating a flashable AnyKernel3 zip package

## Prerequisites

### System Requirements

- **Operating System**: Arch Linux (recommended) or any Linux distribution
- **Disk Space**: Minimum 20GB free space
- **RAM**: 8GB or more recommended
- **CPU**: Multi-core processor (script uses all available cores)

### Required Packages

On Arch Linux, install dependencies with:

```bash
sudo pacman -S base-devel git bc bison flex zip curl wget python3 clang
```

## Quick Start

1. Clone this repository and navigate to it:
   ```bash
   git clone <repository-url>
   cd android_kernel_nothing_sm7635
   ```

2. Run the integration script:
   ```bash
   ./apply_kernelsu_susfs.sh
   ```

3. Wait for the build to complete (30-60 minutes depending on hardware)

4. Flash the generated zip file:
   - Reboot to recovery (TWRP/OrangeFox)
   - Flash `KernelSU-SuSFS-<timestamp>.zip`
   - Reboot to system

## What the Script Does

### Step-by-Step Process

1. **Dependency Check**: Verifies all required tools are installed
2. **Clone KernelSU-Next**: Downloads the latest KernelSU-Next from GitHub
3. **Clone SuSFS**: Attempts to download SuSFS (optional, continues without it if unavailable)
4. **Apply KernelSU-Next**: Uses the official KernelSU-Next setup script to integrate into the kernel
   - Runs `KernelSU-Next/kernel/setup.sh` which handles all integration automatically
   - Creates symlink in `drivers/kernelsu`
   - Updates `drivers/Makefile`
   - Updates `drivers/Kconfig`
5. **Configure Kernel**: Generates kernel configuration with KernelSU-Next enabled
   - Sets `CONFIG_KSU=y`
   - Optionally sets `CONFIG_KSU_SUSFS=y` if SuSFS is available
6. **Build Kernel**: Compiles the kernel with all CPU cores
7. **Package**: Creates AnyKernel3 flashable zip

### Directory Structure

```
android_kernel_nothing_sm7635/
├── apply_kernelsu_susfs.sh    # Main integration script
├── KERNELSU_README.md         # Detailed documentation
├── SETUP_GUIDE.md             # This file
├── test_integration.sh        # Integration test script
├── KernelSU-Next/             # KernelSU-Next repository (cloned by script)
├── kernelsu_work/             # Work directory (created by script)
│   ├── susfs4ksu/            # SuSFS source (if available)
│   └── AnyKernel3/           # AnyKernel3 packaging tool
├── out/                       # Build output directory
└── KernelSU-SuSFS-*.zip      # Final flashable zip
```

## Configuration Options

You can modify the script variables at the top of `apply_kernelsu_susfs.sh`:

```bash
DEFCONFIG="gki_defconfig"              # Kernel configuration to use
KERNELSU_BRANCH="main"                  # KernelSU-Next branch
ARCH=arm64                              # Target architecture
```

## Troubleshooting

### Common Issues

1. **Build fails with compiler errors**
   - Ensure you have clang installed: `sudo pacman -S clang`
   - Check that you have sufficient disk space

2. **SuSFS clone fails**
   - This is normal if GitLab is blocked
   - The script will continue with KernelSU-Next only
   - KernelSU-Next works perfectly fine without SuSFS

3. **Out of memory during build**
   - Close other applications
   - Consider adding swap space
   - Reduce parallel jobs by editing the script: `JOBS=2`

4. **Bootloop after flashing**
   - Reflash your stock kernel
   - Check kernel logs via recovery
   - Report the issue with logs

### Getting Help

- Check the `KERNELSU_README.md` for detailed information
- Review KernelSU documentation: https://kernelsu.org
- Check kernel logs: `adb logcat` or recovery logs

## Safety

⚠️ **Important Safety Notes**

1. **Backup**: Always backup your data before flashing
2. **Recovery**: Keep a working kernel zip handy
3. **Testing**: Test on a non-primary device first if possible
4. **Warranty**: Custom kernels may void your warranty

## Advanced Usage

### Testing Without Building

Run the integration test to verify setup without building:

```bash
./test_integration.sh
```

This tests:
- Dependency availability
- KernelSU cloning
- Integration steps
- AnyKernel3 cloning

### Manual Building

If you want to build manually:

```bash
# Source the script functions
source ./apply_kernelsu_susfs.sh

# Run individual steps
check_dependencies
setup_workdir
clone_kernelsu
apply_kernelsu
configure_kernel
build_kernel
create_ak3_zip
```

### Customizing AnyKernel3

The AnyKernel3 configuration is in `kernelsu_work/AnyKernel3/anykernel.sh`. You can modify it before the zip is created.

## Build Time Estimates

| Hardware | Estimated Time |
|----------|---------------|
| 4-core CPU, 8GB RAM | 45-60 minutes |
| 6-core CPU, 16GB RAM | 30-45 minutes |
| 8+ core CPU, 32GB RAM | 20-30 minutes |

## Files Created

After running the script:

- `KernelSU-SuSFS-<timestamp>.zip` - Flashable kernel package
- `kernelsu_work/` - Work directory (can be deleted after)
- `out/` - Build output (can be deleted after)
- `drivers/kernelsu` - Symlink (removed by cleanup)

## Cleanup

To clean up after building:

```bash
rm -rf kernelsu_work out drivers/kernelsu
git checkout drivers/Makefile drivers/Kconfig
```

Or keep the zip and clean everything else:

```bash
mv KernelSU-SuSFS-*.zip ~/Downloads/
rm -rf kernelsu_work out drivers/kernelsu
git checkout drivers/Makefile drivers/Kconfig
```

## License

This script is provided under GPL-2.0, consistent with the Linux kernel license.

## Credits

- **KernelSU-Next**: https://github.com/KernelSU-Next/KernelSU-Next
- **SuSFS**: https://gitlab.com/simonpunk/susfs4ksu
- **AnyKernel3**: https://github.com/osm0sis/AnyKernel3
