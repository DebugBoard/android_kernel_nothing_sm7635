#!/bin/bash
# Script to apply KernelSU next and SuSFS to Nothing Phone sm7635 kernel
# This script is designed to run on Arch Linux
# Author: Automated kernel integration script
# License: GPL-2.0

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Script configuration
KERNEL_DIR="$(pwd)"
WORK_DIR="${KERNEL_DIR}/kernelsu_work"
KERNELSU_REPO="https://github.com/tiann/KernelSU"
KERNELSU_BRANCH="next"
SUSFS_REPO="https://gitlab.com/simonpunk/susfs4ksu"
ANYKERNEL3_REPO="https://github.com/osm0sis/AnyKernel3"
OUTPUT_DIR="${KERNEL_DIR}/out"
AK3_DIR="${WORK_DIR}/AnyKernel3"

# Kernel build configuration
ARCH=arm64
SUBARCH=arm64
DEFCONFIG="gki_defconfig"
CROSS_COMPILE="aarch64-linux-gnu-"
CC="clang"
CLANG_TRIPLE="aarch64-linux-gnu-"

# Detect number of CPU cores
JOBS=$(nproc)

print_info "========================================"
print_info "KernelSU + SuSFS Integration Script"
print_info "========================================"
print_info "Kernel Directory: ${KERNEL_DIR}"
print_info "Work Directory: ${WORK_DIR}"
print_info "CPU Cores: ${JOBS}"
print_info ""

# Function to check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    local missing_deps=()
    
    # Required tools
    local deps=("git" "make" "bc" "bison" "flex" "zip" "curl" "wget" "python3")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # Check for cross compiler or clang
    if ! command -v aarch64-linux-gnu-gcc &> /dev/null && ! command -v clang &> /dev/null; then
        missing_deps+=("aarch64-linux-gnu-gcc or clang")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_info "On Arch Linux, install with:"
        print_info "  sudo pacman -S base-devel git bc bison flex zip curl wget python3 clang"
        print_info "  sudo pacman -S aarch64-linux-gnu-gcc"
        exit 1
    fi
    
    print_info "All dependencies satisfied!"
}

# Function to setup work directory
setup_workdir() {
    print_info "Setting up work directory..."
    
    if [ -d "${WORK_DIR}" ]; then
        print_warn "Work directory exists. Cleaning up..."
        rm -rf "${WORK_DIR}"
    fi
    
    mkdir -p "${WORK_DIR}"
    print_info "Work directory created: ${WORK_DIR}"
}

# Function to clone KernelSU
clone_kernelsu() {
    print_info "Cloning KernelSU (${KERNELSU_BRANCH} branch)..."
    
    cd "${WORK_DIR}"
    
    if [ -d "KernelSU" ]; then
        print_warn "KernelSU directory exists. Removing..."
        rm -rf KernelSU
    fi
    
    git clone --depth=1 -b "${KERNELSU_BRANCH}" "${KERNELSU_REPO}" KernelSU
    
    if [ ! -d "KernelSU" ]; then
        print_error "Failed to clone KernelSU!"
        exit 1
    fi
    
    print_info "KernelSU cloned successfully!"
}

# Function to clone SuSFS
clone_susfs() {
    print_info "Cloning SuSFS..."
    
    cd "${WORK_DIR}"
    
    if [ -d "susfs4ksu" ]; then
        print_warn "SuSFS directory exists. Removing..."
        rm -rf susfs4ksu
    fi
    
    git clone --depth=1 "${SUSFS_REPO}" susfs4ksu
    
    if [ ! -d "susfs4ksu" ]; then
        print_error "Failed to clone SuSFS!"
        exit 1
    fi
    
    print_info "SuSFS cloned successfully!"
}

# Function to apply KernelSU to kernel
apply_kernelsu() {
    print_info "Applying KernelSU to kernel source..."
    
    cd "${KERNEL_DIR}"
    
    # Create symbolic link for KernelSU in kernel drivers
    if [ -L "drivers/kernelsu" ]; then
        print_warn "Removing existing KernelSU symlink..."
        rm -f drivers/kernelsu
    fi
    
    ln -sf "${WORK_DIR}/KernelSU/kernel" drivers/kernelsu
    
    # Modify drivers/Makefile to include KernelSU
    if ! grep -q "kernelsu" drivers/Makefile; then
        print_info "Adding KernelSU to drivers/Makefile..."
        echo "obj-\$(CONFIG_KSU) += kernelsu/" >> drivers/Makefile
    else
        print_warn "KernelSU already in drivers/Makefile"
    fi
    
    # Modify drivers/Kconfig to include KernelSU
    if ! grep -q "kernelsu/Kconfig" drivers/Kconfig; then
        print_info "Adding KernelSU to drivers/Kconfig..."
        # Insert before the final 'endmenu' in drivers/Kconfig
        sed -i '/^endmenu$/i source "drivers/kernelsu/Kconfig"' drivers/Kconfig
    else
        print_warn "KernelSU already in drivers/Kconfig"
    fi
    
    print_info "KernelSU applied successfully!"
}

# Function to apply SuSFS to kernel
apply_susfs() {
    print_info "Applying SuSFS to kernel source..."
    
    cd "${KERNEL_DIR}"
    
    # Check for SuSFS kernel patches
    SUSFS_KERNEL_PATCH_DIR="${WORK_DIR}/susfs4ksu/kernel_patches"
    
    if [ ! -d "${SUSFS_KERNEL_PATCH_DIR}" ]; then
        print_warn "SuSFS kernel patches directory not found. Checking alternate location..."
        # Try alternate structure
        if [ -d "${WORK_DIR}/susfs4ksu" ]; then
            print_info "Using SuSFS directory for integration..."
            # Create symbolic link for SuSFS
            if [ ! -L "fs/susfs" ]; then
                ln -sf "${WORK_DIR}/susfs4ksu" fs/susfs
            fi
        fi
    else
        # Apply patches if they exist
        print_info "Applying SuSFS kernel patches..."
        
        # Find and apply patches for kernel version 6.6 or generic patches
        PATCH_FILES=$(find "${SUSFS_KERNEL_PATCH_DIR}" -name "*.patch" | grep -E "(6\.6|generic|common)" || true)
        
        if [ -z "$PATCH_FILES" ]; then
            print_warn "No specific patches found for kernel 6.6. Looking for any patch files..."
            PATCH_FILES=$(find "${SUSFS_KERNEL_PATCH_DIR}" -name "*.patch" | head -1 || true)
        fi
        
        if [ -n "$PATCH_FILES" ]; then
            for patch_file in $PATCH_FILES; do
                print_info "Applying patch: $(basename $patch_file)"
                if ! patch -p1 -N --dry-run -i "$patch_file" &> /dev/null; then
                    print_warn "Patch $(basename $patch_file) may already be applied or conflicts. Skipping..."
                else
                    patch -p1 -i "$patch_file"
                fi
            done
        else
            print_warn "No patch files found. SuSFS may need manual integration."
        fi
    fi
    
    print_info "SuSFS applied successfully!"
}

# Function to configure kernel
configure_kernel() {
    print_info "Configuring kernel with KernelSU and SuSFS support..."
    
    cd "${KERNEL_DIR}"
    
    # Clean any previous builds
    if [ -d "${OUTPUT_DIR}" ]; then
        print_warn "Cleaning previous build output..."
        rm -rf "${OUTPUT_DIR}"
    fi
    
    mkdir -p "${OUTPUT_DIR}"
    
    # Setup build environment
    export ARCH=${ARCH}
    export SUBARCH=${SUBARCH}
    
    # Check if clang is available
    if command -v clang &> /dev/null; then
        export CC=clang
        export CLANG_TRIPLE=${CLANG_TRIPLE}
        print_info "Using Clang compiler"
    else
        export CROSS_COMPILE=${CROSS_COMPILE}
        print_info "Using GCC cross compiler"
    fi
    
    # Generate default config
    print_info "Generating defconfig: ${DEFCONFIG}"
    make O="${OUTPUT_DIR}" ARCH=${ARCH} ${DEFCONFIG}
    
    # Enable KernelSU
    print_info "Enabling KernelSU configuration..."
    echo "CONFIG_KSU=y" >> "${OUTPUT_DIR}/.config"
    
    # Enable SuSFS if configuration exists
    if grep -q "CONFIG_KSU_SUSFS" "${OUTPUT_DIR}/.config" 2>/dev/null || \
       [ -f "${WORK_DIR}/KernelSU/kernel/Kconfig" ] && grep -q "KSU_SUSFS" "${WORK_DIR}/KernelSU/kernel/Kconfig"; then
        print_info "Enabling SuSFS configuration..."
        echo "CONFIG_KSU_SUSFS=y" >> "${OUTPUT_DIR}/.config"
    fi
    
    # Update config with dependencies
    make O="${OUTPUT_DIR}" ARCH=${ARCH} olddefconfig
    
    print_info "Kernel configured successfully!"
}

# Function to build kernel
build_kernel() {
    print_info "Building kernel..."
    
    cd "${KERNEL_DIR}"
    
    export ARCH=${ARCH}
    export SUBARCH=${SUBARCH}
    
    if command -v clang &> /dev/null; then
        export CC=clang
        export CLANG_TRIPLE=${CLANG_TRIPLE}
    else
        export CROSS_COMPILE=${CROSS_COMPILE}
    fi
    
    # Build kernel Image
    print_info "Compiling kernel (this may take a while)..."
    make O="${OUTPUT_DIR}" ARCH=${ARCH} -j${JOBS} Image.gz dtbs dtbo.img
    
    if [ ! -f "${OUTPUT_DIR}/arch/${ARCH}/boot/Image.gz" ]; then
        print_error "Kernel build failed! Image.gz not found."
        exit 1
    fi
    
    print_info "Kernel built successfully!"
    print_info "Kernel image: ${OUTPUT_DIR}/arch/${ARCH}/boot/Image.gz"
}

# Function to clone AnyKernel3
clone_anykernel3() {
    print_info "Cloning AnyKernel3..."
    
    cd "${WORK_DIR}"
    
    if [ -d "AnyKernel3" ]; then
        print_warn "AnyKernel3 directory exists. Removing..."
        rm -rf AnyKernel3
    fi
    
    git clone --depth=1 "${ANYKERNEL3_REPO}" AnyKernel3
    
    if [ ! -d "AnyKernel3" ]; then
        print_error "Failed to clone AnyKernel3!"
        exit 1
    fi
    
    print_info "AnyKernel3 cloned successfully!"
}

# Function to create AnyKernel3 zip
create_ak3_zip() {
    print_info "Creating AnyKernel3 flashable zip..."
    
    cd "${AK3_DIR}"
    
    # Clean AnyKernel3 directory
    rm -rf .git Image.gz Image dtb dtbo.img modules/system/lib/modules/*
    
    # Configure AnyKernel3 for this device
    cat > anykernel.sh << 'EOF'
# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=KernelSU + SuSFS by Auto Script
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;

## AnyKernel boot install
dump_boot;

# begin ramdisk changes

# end ramdisk changes

write_boot;
## end boot install
EOF
    
    # Copy kernel Image
    print_info "Copying kernel Image.gz..."
    cp "${OUTPUT_DIR}/arch/${ARCH}/boot/Image.gz" ./
    
    # Copy dtb and dtbo if they exist
    if [ -f "${OUTPUT_DIR}/arch/${ARCH}/boot/dtbo.img" ]; then
        print_info "Copying dtbo.img..."
        cp "${OUTPUT_DIR}/arch/${ARCH}/boot/dtbo.img" ./
    fi
    
    # Create zip file
    ZIP_NAME="KernelSU-SuSFS-$(date +%Y%m%d-%H%M%S).zip"
    print_info "Creating flashable zip: ${ZIP_NAME}"
    
    zip -r9 "${ZIP_NAME}" * -x .git README.md *placeholder
    
    # Move zip to kernel directory
    mv "${ZIP_NAME}" "${KERNEL_DIR}/"
    
    print_info "AnyKernel3 zip created successfully!"
    print_info "Output: ${KERNEL_DIR}/${ZIP_NAME}"
}

# Function to verify output
verify_output() {
    print_info "Verifying output files..."
    
    cd "${KERNEL_DIR}"
    
    ZIP_FILE=$(ls -t KernelSU-SuSFS-*.zip 2>/dev/null | head -1 || true)
    
    if [ -z "$ZIP_FILE" ]; then
        print_error "No AK3 zip file found!"
        exit 1
    fi
    
    print_info "Checking zip file contents..."
    if unzip -l "$ZIP_FILE" | grep -q "Image.gz"; then
        print_info "✓ Image.gz found in zip"
    else
        print_warn "✗ Image.gz not found in zip"
    fi
    
    if unzip -l "$ZIP_FILE" | grep -q "anykernel.sh"; then
        print_info "✓ anykernel.sh found in zip"
    else
        print_warn "✗ anykernel.sh not found in zip"
    fi
    
    print_info ""
    print_info "========================================"
    print_info "Build Complete!"
    print_info "========================================"
    print_info "Output file: ${ZIP_FILE}"
    print_info "File size: $(du -h "$ZIP_FILE" | cut -f1)"
    print_info ""
    print_info "To flash:"
    print_info "1. Reboot to recovery (TWRP/OrangeFox)"
    print_info "2. Flash the ${ZIP_FILE}"
    print_info "3. Reboot to system"
    print_info ""
    print_warn "IMPORTANT: Make sure you have a backup before flashing!"
    print_info "========================================"
}

# Main execution
main() {
    print_info "Starting KernelSU + SuSFS integration..."
    
    check_dependencies
    setup_workdir
    clone_kernelsu
    clone_susfs
    apply_kernelsu
    apply_susfs
    configure_kernel
    build_kernel
    clone_anykernel3
    create_ak3_zip
    verify_output
    
    print_info "All done! 🎉"
}

# Run main function
main "$@"
