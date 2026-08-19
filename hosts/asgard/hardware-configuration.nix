{ modulesPath, ... }:
{
  imports = [ "${modulesPath}/installer/scan/not-detected.nix" ];

  boot.initrd.availableKernelModules = [ "ahci" "nvme" "sd_mod" "usb_storage" "usbhid" "xhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];

  boot.loader.systemd-boot.extraEntries = {
    "windows.conf" = ''
      title Windows 11
      efi (hd1,gpt1)/EFI/Microsoft/Boot/bootmgfw.efi
    '';
  };

  fileSystems."/" = { device = "/dev/nvme0n1p2"; fsType = "btrfs"; options = [ "subvol=@" "compress=zstd" ]; };
  fileSystems."/home" = { device = "/dev/nvme0n1p2"; fsType = "btrfs"; options = [ "subvol=@home" "compress=zstd" ]; };
  fileSystems."/nix" = { device = "/dev/nvme0n1p2"; fsType = "btrfs"; options = [ "subvol=@nix" "compress=zstd" ]; };
  fileSystems."/var/log" = { device = "/dev/nvme0n1p2"; fsType = "btrfs"; options = [ "subvol=@log" "compress=zstd" ]; };
  fileSystems."/boot" = { device = "/dev/nvme0n1p1"; fsType = "vfat"; };
}
