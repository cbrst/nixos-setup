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

  fileSystems."/" = { device = "/dev/disk/by-uuid/8b13f91d-7bc5-435e-adae-d7539e63fde9"; fsType = "btrfs"; options = [ "subvol=@" "compress=zstd" ]; };
  fileSystems."/home" = { device = "/dev/disk/by-uuid/8b13f91d-7bc5-435e-adae-d7539e63fde9"; fsType = "btrfs"; options = [ "subvol=@home" "compress=zstd" ]; };
  fileSystems."/nix" = { device = "/dev/disk/by-uuid/8b13f91d-7bc5-435e-adae-d7539e63fde9"; fsType = "btrfs"; options = [ "subvol=@nix" "compress=zstd" ]; };
  fileSystems."/var/log" = { device = "/dev/disk/by-uuid/8b13f91d-7bc5-435e-adae-d7539e63fde9"; fsType = "btrfs"; options = [ "subvol=@log" "compress=zstd" ]; };
  fileSystems."/boot" = { device = "/dev/disk/by-uuid/0155-1CB0"; fsType = "vfat"; };
}
