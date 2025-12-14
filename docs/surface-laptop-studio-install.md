# Installing NixOS on Surface Laptop Studio

This guide walks you through installing NixOS on a Microsoft Surface Laptop Studio (SLS1 or SLS2) and cloning this dotfiles configuration.

> **Note:** This configuration addresses all known linux-surface issues for the Surface Laptop Studio. See [Known Issues Addressed](#known-issues-addressed) below.

## Prerequisites

- USB drive (8GB minimum)
- Ethernet adapter OR USB tethering (WiFi driver may not work on minimal ISO)
- Another device to create the USB installer (or access from Windows)

---

## Part 1: Prepare Windows

### 1.1 Disable Secure Boot (Temporarily)

1. Power off the Surface completely
2. Hold **Volume Up** + **Power** until you see the Surface UEFI
3. Navigate to **Security** → **Secure Boot**
4. Set to **Disabled** (we'll re-enable later with custom keys)
5. **Save and Exit**

### 1.2 Shrink Windows Partition (if dual-booting)

1. Open **Disk Management** (right-click Start → Disk Management)
2. Right-click on the largest partition (usually C:)
3. Select **Shrink Volume**
4. Shrink by at least **100GB** (more recommended)
5. Leave the space as **Unallocated** (NixOS will use it)

> **Tip:** If you want to completely replace Windows, skip this step and delete partitions during installation.

---

## Part 2: Create NixOS USB Installer

### Option A: Using Rufus (from Windows)

1. Download the [NixOS Minimal ISO](https://nixos.org/download.html#nixos-iso) (64-bit, minimal)
2. Download [Rufus](https://rufus.ie/)
3. Insert USB drive
4. In Rufus:
   - Select your USB drive
   - Select the NixOS ISO
   - Partition scheme: **GPT**
   - Target system: **UEFI**
   - Click **Start** (use DD mode if prompted)

### Option B: Using Ventoy

1. Install [Ventoy](https://www.ventoy.net/) to your USB drive
2. Copy the NixOS ISO to the Ventoy partition
3. Boot and select the NixOS ISO from the menu

---

## Part 3: Boot into NixOS Installer

1. Power off the Surface
2. Insert the USB drive
3. Hold **Volume Down** + **Power** to boot from USB
4. Select **NixOS** from the boot menu

### 3.1 Connect to Internet

**Recommended:** Use a USB Ethernet adapter or USB tethering from your phone.

```bash
# Verify network (should show an IP)
ip addr
ping -c 3 nixos.org
```

**If using WiFi** (may require linux-surface kernel, might not work on minimal ISO):

```bash
# Connect to WiFi
sudo systemctl start wpa_supplicant
wpa_cli
> add_network
> set_network 0 ssid "YOUR_WIFI_NAME"
> set_network 0 psk "YOUR_WIFI_PASSWORD"
> enable_network 0
> quit

# Wait for connection
ip addr
```

---

## Part 4: Partition the Disk

### 4.1 Identify Your Disk

```bash
lsblk
```

Look for your NVMe drive (usually `nvme0n1`). Note the size to confirm it's the correct drive.

### 4.2 Partitioning with `parted`

```bash
sudo parted /dev/nvme0n1
```

**If replacing Windows entirely:**

```parted
(parted) mklabel gpt
(parted) mkpart ESP fat32 1MiB 1GiB
(parted) set 1 esp on
(parted) mkpart nixos btrfs 1GiB 100%
(parted) quit
```

**If dual-booting** (use the unallocated space):

```parted
(parted) print  # Note the end of the last partition
(parted) mkpart nixos btrfs <END>GiB 100%
(parted) quit
```

### 4.3 Set Up LUKS Encryption

```bash
# Encrypt the main partition (partition 2 if replacing Windows)
sudo cryptsetup luksFormat /dev/nvme0n1p2

# Open the encrypted volume
sudo cryptsetup open /dev/nvme0n1p2 encrypted
```

### 4.4 Create BTRFS Filesystem and Subvolumes

```bash
# Format as BTRFS
sudo mkfs.btrfs /dev/mapper/encrypted

# Mount for subvolume creation
sudo mount /dev/mapper/encrypted /mnt

# Create subvolumes (matching the config)
sudo btrfs subvolume create /mnt/root
sudo btrfs subvolume create /mnt/home
sudo btrfs subvolume create /mnt/nix
sudo btrfs subvolume create /mnt/persist
sudo btrfs subvolume create /mnt/log
sudo btrfs subvolume create /mnt/swap

# Unmount
sudo umount /mnt
```

### 4.5 Mount Subvolumes

```bash
# Mount options for performance
MOUNT_OPTS="compress=zstd,noatime,ssd,discard=async"

# Mount root subvolume
sudo mount -o subvol=root,$MOUNT_OPTS /dev/mapper/encrypted /mnt

# Create mount points
sudo mkdir -p /mnt/{boot,home,nix,persist,var/log,swap}

# Mount subvolumes
sudo mount -o subvol=home,$MOUNT_OPTS /dev/mapper/encrypted /mnt/home
sudo mount -o subvol=nix,$MOUNT_OPTS /dev/mapper/encrypted /mnt/nix
sudo mount -o subvol=persist,$MOUNT_OPTS /dev/mapper/encrypted /mnt/persist
sudo mount -o subvol=log,$MOUNT_OPTS /dev/mapper/encrypted /mnt/var/log
sudo mount -o subvol=swap,noatime /dev/mapper/encrypted /mnt/swap

# Mount boot partition (partition 1)
sudo mkfs.fat -F32 /dev/nvme0n1p1  # Skip if dual-boot (use existing EFI)
sudo mount /dev/nvme0n1p1 /mnt/boot
```

### 4.6 Create Swap File for Hibernation

```bash
# Create 32GB swap file (adjust based on RAM)
sudo btrfs filesystem mkswapfile --size 32G /mnt/swap/swapfile
sudo swapon /mnt/swap/swapfile

# Get the swap file offset (needed for hibernation)
sudo filefrag -v /mnt/swap/swapfile | head -n 4
# Note the first "physical_offset" value (e.g., 533760)
```

---

## Part 5: Generate Configuration and Clone Dotfiles

### 5.1 Generate Hardware Configuration

```bash
sudo nixos-generate-config --root /mnt
```

This creates `/mnt/etc/nixos/hardware-configuration.nix` with your UUIDs.

### 5.2 Get UUID Information

```bash
# LUKS UUID (for boot.initrd.luks.devices)
sudo blkid /dev/nvme0n1p2 | grep -oP 'UUID="\K[^"]+'

# BTRFS UUID (for fileSystems)
sudo blkid /dev/mapper/encrypted | grep -oP 'UUID="\K[^"]+'

# Boot partition UUID
sudo blkid /dev/nvme0n1p1 | grep -oP 'UUID="\K[^"]+'
```

**Write these down!** You'll need them for the configuration.

### 5.3 Clone This Configuration

```bash
# Install git
nix-shell -p git

# Clone the dotfiles
cd /mnt
sudo git clone https://github.com/tama-gucci/.dotfiles.git

# Navigate to the config
cd /mnt/.dotfiles
```

### 5.4 Update diatom.nix with Your UUIDs

Edit the host configuration to add your filesystem UUIDs:

```bash
sudo nano modules/hosts/diatom.nix
```

Find the `PLACEHOLDER: FILESYSTEMS` section and uncomment/update:

```nix
# LUKS device
boot.initrd.luks.devices."encrypted".device = 
  "/dev/disk/by-uuid/YOUR-LUKS-UUID";

# Root filesystem
fileSystems."/" = {
  device = "/dev/disk/by-uuid/YOUR-BTRFS-UUID";
  fsType = "btrfs";
  options = [ "subvol=root" "compress=zstd" "noatime" "ssd" "discard=async" ];
};

fileSystems."/home" = {
  device = "/dev/disk/by-uuid/YOUR-BTRFS-UUID";
  fsType = "btrfs";
  options = [ "subvol=home" "compress=zstd" "noatime" "ssd" "discard=async" ];
};

fileSystems."/nix" = {
  device = "/dev/disk/by-uuid/YOUR-BTRFS-UUID";
  fsType = "btrfs";
  options = [ "subvol=nix" "compress=zstd" "noatime" "ssd" "discard=async" ];
};

fileSystems."/persist" = {
  device = "/dev/disk/by-uuid/YOUR-BTRFS-UUID";
  fsType = "btrfs";
  options = [ "subvol=persist" "compress=zstd" "noatime" "ssd" "discard=async" ];
};

fileSystems."/var/log" = {
  device = "/dev/disk/by-uuid/YOUR-BTRFS-UUID";
  fsType = "btrfs";
  options = [ "subvol=log" "compress=zstd" "noatime" "ssd" "discard=async" ];
  neededForBoot = true;
};

fileSystems."/swap" = {
  device = "/dev/disk/by-uuid/YOUR-BTRFS-UUID";
  fsType = "btrfs";
  options = [ "subvol=swap" "noatime" ];
};

fileSystems."/boot" = {
  device = "/dev/disk/by-uuid/YOUR-BOOT-UUID";
  fsType = "vfat";
};
```

Also update the hibernation offset:

```nix
hibernation = {
  enable = true;
  device = "/dev/nvme0n1p2";  # Your encrypted partition
  offset = "YOUR-SWAP-OFFSET";  # From filefrag command
  swapSize = "32G";
};
```

### 5.5 Verify GPU Bus IDs

```bash
lspci | grep VGA
```

Update the bus IDs in diatom.nix if they differ from the defaults:

```nix
nvidia = {
  # ...
  prime = {
    intelBusId = "PCI:0:2:0";   # Intel graphics
    nvidiaBusId = "PCI:1:0:0";  # NVIDIA GPU (update if different)
  };
};
```

---

## Part 6: Install NixOS

### 6.1 Build and Install

```bash
# From the dotfiles directory
sudo nixos-install --flake .#diatom
```

This will:
- Build the entire system
- Install to `/mnt`
- Prompt you to set the root password

### 6.2 Set User Password

```bash
# Set password for your user
sudo nixos-enter --root /mnt -c 'passwd sin'
```

### 6.3 Reboot

```bash
sudo reboot
```

Remove the USB drive when prompted.

---

## Part 7: Post-Installation Setup

### 7.1 First Boot

1. Select "NixOS" from the boot menu
2. Enter your LUKS passphrase
3. Log in with your user credentials

### 7.2 Clone Dotfiles to Home Directory

```bash
cd ~
git clone https://github.com/tama-gucci/.dotfiles.git
cd .dotfiles
```

### 7.3 Test Hardware

```bash
# Check touchscreen
libinput debug-events  # Touch the screen, should see events

# Check NVIDIA GPU
nvidia-smi

# Check Surface features
surface status
surface performance get

# Check audio
pactl info | grep "Sample Specification"  # Should show 48000 Hz
```

### 7.4 Verify GPU Power Limit Fix

```bash
# Check GPU power state (should be D0 when in use)
cat /sys/bus/pci/devices/0000:01:00.0/power_state

# Run a GPU workload and check power
nvidia-smi -q | grep -A 3 "Power Readings"
# Should show > 10W when under load (up to ~35W)
```

### 7.5 Re-enable Secure Boot (Optional)

This configuration includes lanzaboote for Secure Boot. To enable:

```bash
# Generate Secure Boot keys
sudo sbctl create-keys

# Enroll keys in firmware (with Microsoft keys for dual-boot)
sudo sbctl enroll-keys --microsoft

# Verify signed files
sudo sbctl verify

# Rebuild to sign boot files
sudo nixos-rebuild switch --flake ~/.dotfiles#diatom
```

Then reboot and re-enable Secure Boot in UEFI.

---

## Known Issues Addressed

This configuration automatically handles these Surface Laptop Studio issues documented in the [linux-surface wiki](https://github.com/linux-surface/linux-surface/wiki/Surface-Laptop-Studio):

### 1. Touchpad Cursor Issues (SLS1)
**Problem:** Cursor doesn't move or stops when selecting text/dragging files due to false palm detection.

**Solution:** Libinput quirk applied automatically via `surface.quirks.touchpadPalmDetection`.

### 2. Keyboard/Touchpad Disabled in Slate Mode (Wayland)
**Problem:** On Wayland, libinput disables keyboard and touchpad when the screen is in slate/tablet position.

**Solution:** Libinput quirk applied automatically via `surface.quirks.slateModePeripherals`.

### 3. Poor Audio Quality at 44.1kHz
**Problem:** Internal speakers produce degraded audio at 44.1kHz sample rate.

**Solution:** PipeWire forced to 48kHz via Surface module configuration.

### 4. NVIDIA GPU Locked at 10W Power Limit
**Problem:** The dGPU gets stuck at 10W (instead of 50W max) after entering/exiting D3cold power state.

**Solution:** Runtime D3 is disabled via `nvidia.disableRuntimeD3 = true`. This restores 35W of the 50W limit.

> **Trade-off:** With Runtime D3 disabled, the GPU cannot fully power down, resulting in slightly higher idle power consumption. For maximum battery life when unplugged and not gaming, consider using the `nvidia-sync` specialization or Intel-only mode.

### 5. IPTSD Touchpad Issues (SLS2)
**Problem:** On Surface Laptop Studio 2, the touchpad may act like a touchscreen (1-to-1 mapping).

**Solution:** For SLS2, set `surface.model = "laptop-studio-2"` which applies IPTSD calibration settings automatically.

---

## Configuration Options Reference

### Surface Module (`surface.nix`)

```nix
surface = {
  model = "laptop-studio";  # or "laptop-studio-2", "pro-intel", "laptop-amd", "go"
  kernelVersion = "stable"; # or "longterm" (LTS)
  touchscreen.enable = true;
  
  quirks = {
    touchpadPalmDetection = true;      # Auto-enabled for SLS1
    slateModePeripherals = true;       # Auto-enabled for SLS1/SLS2
    iptsdTouchpadCalibration = false;  # Auto-enabled for SLS2
  };
};
```

### NVIDIA Module (`nvidia.nix`)

```nix
nvidia = {
  useCustomKernel = false;    # Use linux-surface kernel instead of CachyOS
  disableRuntimeD3 = true;    # Fix 10W power limit (increases idle power)
  
  prime = {
    enable = true;
    mode = "offload";         # "offload", "sync", or "reverse-sync"
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
};
```

---

## Troubleshooting

### WiFi Not Working
The minimal NixOS ISO may not have Surface WiFi drivers. Use USB Ethernet or phone tethering during installation.

### No Display on Boot
Try adding `nomodeset` to kernel parameters during boot (press `e` in boot menu).

### Touch/Pen Not Working
Verify IPTSD is running:
```bash
systemctl status iptsd
```

### GPU Issues
Check if NVIDIA driver loaded:
```bash
lsmod | grep nvidia
nvidia-smi
```

### Audio Issues
Restart PipeWire:
```bash
systemctl --user restart pipewire pipewire-pulse
```

### Hibernation Not Working
Verify swap file offset matches configuration:
```bash
sudo filefrag -v /swap/swapfile | head -n 4
```

---

## Useful Commands

```bash
# Rebuild system after changes
sudo nixos-rebuild switch --flake ~/.dotfiles#diatom

# Update flake inputs
nix flake update

# Surface control commands
surface status
surface performance set normal  # or "low", "high"
surface kbd brightness set 100  # Keyboard backlight

# GPU commands
nvidia-offload <command>  # Run with NVIDIA GPU
nvidia-smi                # Check GPU status
```

---

## Resources

- [linux-surface Wiki](https://github.com/linux-surface/linux-surface/wiki)
- [Surface Laptop Studio Issues](https://github.com/linux-surface/linux-surface/wiki/Surface-Laptop-Studio)
- [nixos-hardware Surface modules](https://github.com/NixOS/nixos-hardware/tree/master/microsoft/surface)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
