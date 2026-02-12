#!/bin/bash
# Test script for KernelSU-Next integration
# This tests all the components without doing a full kernel build

# Don't exit on error - we want to see all test results
set +e

echo "=== KernelSU-Next Integration Test ==="
echo ""

# Source the main script (but main won't run because of the guard)
source ./apply_kernelsu_susfs.sh

# Test 1: Dependencies
echo "Test 1: Checking dependencies..."
check_dependencies
if [ $? -eq 0 ]; then
    echo "✓ Dependencies check passed"
else
    echo "✗ Dependencies check failed"
    exit 1
fi
echo ""

# Test 2: Work directory setup
echo "Test 2: Setting up work directory..."
setup_workdir
if [ -d "kernelsu_work" ]; then
    echo "✓ Work directory created"
else
    echo "✗ Work directory not created"
    exit 1
fi
echo ""

# Test 3: KernelSU-Next cloning
echo "Test 3: Cloning KernelSU-Next..."
clone_kernelsu
if [ -d "KernelSU-Next/kernel" ]; then
    echo "✓ KernelSU-Next cloned successfully"
    echo "  Files found: $(ls KernelSU-Next/kernel/*.c 2>/dev/null | wc -l) C files"
else
    echo "✗ KernelSU-Next not cloned properly"
    exit 1
fi
echo ""

# Test 4: KernelSU-Next application
echo "Test 4: Applying KernelSU-Next to kernel..."
apply_kernelsu
if [ -L "drivers/kernelsu" ]; then
    echo "✓ KernelSU-Next symlink created"
else
    echo "✗ KernelSU-Next symlink not created"
    exit 1
fi

if grep -q "kernelsu" drivers/Makefile; then
    echo "✓ KernelSU-Next added to drivers/Makefile"
else
    echo "✗ KernelSU-Next not in drivers/Makefile"
    exit 1
fi

if grep -q "kernelsu/Kconfig" drivers/Kconfig; then
    echo "✓ KernelSU-Next added to drivers/Kconfig"
else
    echo "✗ KernelSU-Next not in drivers/Kconfig"
    exit 1
fi
echo ""

# Test 5: Kernel configuration function
echo "Test 5: Checking kernel configuration function..."
# Just verify the function exists - actual config requires proper toolchain
if declare -f configure_kernel > /dev/null; then
    echo "✓ configure_kernel function exists and is callable"
else
    echo "✗ configure_kernel function not found"
    exit 1
fi

# Verify KernelSU-Next Kconfig exists
if [ -f "KernelSU-Next/kernel/Kconfig" ]; then
    echo "✓ KernelSU-Next Kconfig file found"
    if grep -q "config KSU" KernelSU-Next/kernel/Kconfig; then
        echo "✓ KernelSU-Next Kconfig has CONFIG_KSU option"
    fi
else
    echo "⚠ KernelSU-Next Kconfig not found"
fi
echo ""

# Test 6: AnyKernel3 cloning
echo "Test 6: Cloning AnyKernel3..."
clone_anykernel3
if [ -d "kernelsu_work/AnyKernel3" ]; then
    echo "✓ AnyKernel3 cloned successfully"
    if [ -f "kernelsu_work/AnyKernel3/anykernel.sh" ]; then
        echo "✓ AnyKernel3 scripts found"
    fi
else
    echo "✗ AnyKernel3 not cloned"
    exit 1
fi
echo ""

# Cleanup
echo "Cleaning up test artifacts..."
rm -rf kernelsu_work out drivers/kernelsu KernelSU-Next
git checkout drivers/Makefile drivers/Kconfig 2>/dev/null || true

echo ""
echo "==================================="
echo "All tests passed! ✓"
echo "==================================="
echo ""
echo "The script is ready to use. Run:"
echo "  ./apply_kernelsu_susfs.sh"
echo ""
echo "Note: A full build will take 30-60 minutes depending on your hardware."
