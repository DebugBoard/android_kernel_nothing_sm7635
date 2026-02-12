# KernelSU-Next Integration Notes

## Official Setup Script Usage

This script now uses the official KernelSU-Next setup script (`kernel/setup.sh`) for integration, ensuring compatibility and proper setup according to the upstream project's recommendations.

### Key Changes

1. **Official Setup Script**: Instead of manually creating symlinks and modifying Makefile/Kconfig, the script now:
   - Clones KernelSU-Next to the kernel root directory
   - Executes the official `KernelSU-Next/kernel/setup.sh` script
   - This ensures all integration steps are performed correctly according to upstream standards

2. **Directory Structure**: KernelSU-Next is now cloned directly to the kernel root (`android_kernel_nothing_sm7635/KernelSU-Next/`) instead of a subdirectory in `kernelsu_work/`

3. **Automated Integration**: The setup.sh script automatically:
   - Creates the symlink `drivers/kernelsu` pointing to `KernelSU-Next/kernel`
   - Updates `drivers/Makefile` with the KernelSU build directive
   - Updates `drivers/Kconfig` to source the KernelSU configuration

### Benefits

- **Upstream Compatibility**: Uses the same integration method recommended by KernelSU-Next developers
- **Future-proof**: Any updates to the integration process in KernelSU-Next will be automatically used
- **Tested Method**: The official setup script is maintained and tested by the KernelSU-Next team
- **No Manual Patches Required**: All integration is handled by the official script

### SuSFS Integration

SuSFS integration remains optional and is handled separately:
- If SuSFS repository is accessible, patches will be applied
- If not accessible (e.g., GitLab blocked), the build continues with KernelSU-Next only
- The script gracefully handles both scenarios

### Kernel Version Compatibility

The kernel version is 6.6.114, and the script is configured to:
- Use the main branch of KernelSU-Next
- Look for kernel 6.6-specific patches for SuSFS if available
- Fall back to generic patches if version-specific ones aren't found

### What This Means

Users can now be confident that:
1. The integration follows official KernelSU-Next guidelines
2. The setup is identical to what KernelSU-Next developers recommend
3. Future updates will be seamlessly integrated
4. No manual intervention is required for basic integration
