# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./cachix.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Setup keyfile

  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # Enable grub cryptodisk
  boot.loader.grub.enableCryptodisk=true;

  boot.initrd.luks.devices."luks-45bca1c7-3bce-4046-872b-f31a9cc1444e".keyFile = "/crypto_keyfile.bin";
  # Enable swap on luks
  boot.initrd.luks.devices."luks-475bf6ac-ec0d-41d3-86bb-959c1a64b185".device = "/dev/disk/by-uuid/475bf6ac-ec0d-41d3-86bb-959c1a64b185";
  boot.initrd.luks.devices."luks-475bf6ac-ec0d-41d3-86bb-959c1a64b185".keyFile = "/crypto_keyfile.bin";

  networking.hostName = "stinkpad"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  
  # Auto-update
  
 # system.autoUpgrade = {
 #   enable = true;
 #   channel = "https://nixos.org/channels/nixos-unstable";
 # };
  
  # Flakes

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
    allowedUsers = [ "@wheel" ];
  };

  # modprobe 

  boot.extraModprobeConfig = ''
    blacklist wacom
    blacklist hid_uclogic
  '';
  
  # Hardening
  boot.kernelPackages = pkgs.linuxPackages_hardened;

  security.allowUserNamespaces = true;

  #environment.memoryAllocator.provider = "scudo";
  #environment.variables.SCUDO_OPTIONS =  "ZeroContents=1";

  security.protectKernelImage = true;

  #boot.kernel.sysctl."kernel.yama.ptrace_scope" = 2;
  boot.kernel.sysctl."kernel.sysrq" = 0;
  boot.kernel.sysctl."kernel.unprivileged_bpf_disabled" = 1;
  boot.kernel.sysctl."kernel.kptr_restrict" = 2;
  boot.kernel.sysctl."fs.protected_fifos" = 2;
  boot.kernel.sysctl."fs.protected_regular" = 2;
  boot.kernel.sysctl."fs.suid_dumpable" = 0;


  #security.forcePageTableIsolation = true;

  # Apparmor

  security.apparmor.enable = true;
  security.apparmor.killUnconfinedConfinables = true;

  # This is required by podman to run containers in rootless mode.
  security.unprivilegedUsernsClone = config.virtualisation.containers.enable;

  # Audit

  security.auditd.enable = true;

  boot.kernelParams = [
    # Slab/slub sanity checks, redzoning, and poisoning
    "slub_debug=FZP"

    # Overwrite free'd memory
    "page_poison=1"

    # Enable page allocator randomization
    "page_alloc.shuffle=1"

    "security=apparmor"
    "psmouse.synaptics_intertouch=0"
    "i8042.nomux=1"
    "i8042.reset"
  ];

  boot.blacklistedKernelModules = [
    # Obscure network protocols
    "ax25"
    "netrom"
    "rose"

    # Old or rare or insufficiently audited filesystems
    "adfs"
    "affs"
    "bfs"
    "befs"
    "cramfs"
    "efs"
    "erofs"
    "exofs"
    "freevxfs"
    "f2fs"
    "hfs"
    "hpfs"
    "jfs"
    "minix"
    "nilfs2"
    "ntfs"
    "omfs"
    "qnx4"
    "qnx6"
    "sysv"
    "ufs"
     
     # Custom

     "dccp"
     "sctp"
     "rds"
     "tipc"
  ];

  # Restrict ptrace() usage to processes with a pre-defined relationship
  # (e.g., parent/child)
  #boot.kernel.sysctl."kernel.yama.ptrace_scope" = 1;

  systemd.coredump.enable = false;

  #services.clamav.daemon.enable = true;
  #services.clamav.updater.enable = true;

  # Hide kptrs even for processes with CAP_SYSLOG
  #boot.kernel.sysctl."kernel.kptr_restrict" = 2;

  # Disable bpf() JIT (to eliminate spray attacks)
  #boot.kernel.sysctl."net.core.bpf_jit_enable" = false;

  # Disable ftrace debugging
  #boot.kernel.sysctl."kernel.ftrace_enabled" = false;

  # Enable strict reverse path filtering (that is, do not attempt to route
  # packets that "obviously" do not belong to the iface's network; dropped
  # packets are logged as martians).
  boot.kernel.sysctl."net.ipv4.conf.all.log_martians" = true;
  boot.kernel.sysctl."net.ipv4.conf.all.rp_filter" =  "1";
  boot.kernel.sysctl."net.ipv4.conf.default.log_martians" = true;
  boot.kernel.sysctl."net.ipv4.conf.default.rp_filter" = "1";

  # Ignore broadcast ICMP (mitigate SMURF)
  boot.kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = true;

  # Ignore incoming ICMP redirects (note: default is needed to ensure that the
  # setting is applied to interfaces added after the sysctls are set)
  boot.kernel.sysctl."net.ipv4.conf.all.accept_redirects" = false;
  boot.kernel.sysctl."net.ipv4.conf.all.secure_redirects" =  false;
  boot.kernel.sysctl."net.ipv4.conf.default.accept_redirects" = false;
  boot.kernel.sysctl."net.ipv4.conf.default.secure_redirects" = false;
  boot.kernel.sysctl."net.ipv6.conf.all.accept_redirects" = false;
  boot.kernel.sysctl."net.ipv6.conf.default.accept_redirects" = false;

  # Ignore outgoing ICMP redirects (this is ipv4 only)
  boot.kernel.sysctl."net.ipv4.conf.all.send_redirects" = false;
  boot.kernel.sysctl."net.ipv4.conf.default.send_redirects" = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.utf8";

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.widward = {
    isNormalUser = true;
    description = "stinkpad";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
    packages = with pkgs; [
         firefox
	 mpv
	 neovim
	 ranger
	 feh
	 pulsemixer
	 wget
	 neofetch
	 pass
	 spotifyd
	 spotify-tui
	 nsxiv
	 ani-cli
	 ffmpeg
	 axel
	 cachix
	 neofetch
	 xdragon
     ];
  };
  

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  dwm
  xterm
  dwmblocks
  st
  dmenu
  polybar
  sxhkd
  alacritty
  pulseaudio  
  wineWowPackages.stableFull
  winetricks
  policycoreutils
  dunst
  lightlocker
  libnotify
  bash-completion
  git
  ];

fonts.fonts = with pkgs; [
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  liberation_ttf
  fira-code
  fira-code-symbols
  dina-font
  proggyfonts
  terminus_font
  font-awesome
];

security.rtkit.enable = true;

sound.enable = false;

services.dbus.packages = [  pkgs.gcr ];
 
services.pipewire.enable = true;
services.pipewire.alsa.enable = true;
services.pipewire.pulse.enable = true;
services.pipewire = {
  config.pipewire = {
    "context.properties" = {
      "link.max-buffers" = 16;
      "log.level" = 2;
      "default.clock.rate" = 48000;
      "default.clock.quantum" = 84;
      "default.clock.min-quantum" = 84;
      "default.clock.max-quantum" = 84;
      "core.daemon" = true;
      "core.name" = "pipewire-0";
    };
    "context.modules" = [
      {
        name = "libpipewire-module-rtkit";
        args = {
          "nice.level" = -15;
          "rt.prio" = 88;
          "rt.time.soft" = 200000;
          "rt.time.hard" = 200000;
        };
        flags = [ "ifexists" "nofail" ];
      }
      { name = "libpipewire-module-protocol-native"; }
      { name = "libpipewire-module-profiler"; }
      { name = "libpipewire-module-metadata"; }
      { name = "libpipewire-module-spa-device-factory"; }
      { name = "libpipewire-module-spa-node-factory"; }
      { name = "libpipewire-module-client-node"; }
      { name = "libpipewire-module-client-device"; }
      {
        name = "libpipewire-module-portal";
        flags = [ "ifexists" "nofail" ];
      }
      {
        name = "libpipewire-module-access";
        args = {};
      }
      { name = "libpipewire-module-adapter"; }
      { name = "libpipewire-module-link-factory"; }
      { name = "libpipewire-module-session-manager"; }
    ];
  };
    config.pipewire-pulse = {
    "context.properties" = {
      "log.level" = 2;
    };
    "context.modules" = [
      {
        name = "libpipewire-module-rtkit";
        args = {
          "nice.level" = -15;
          "rt.prio" = 88;
          "rt.time.soft" = 200000;
          "rt.time.hard" = 200000;
        };
        flags = [ "ifexists" "nofail" ];
      }
      { name = "libpipewire-module-protocol-native"; }
      { name = "libpipewire-module-client-node"; }
      { name = "libpipewire-module-adapter"; }
      { name = "libpipewire-module-metadata"; }
      {
        name = "libpipewire-module-protocol-pulse";
        args = {
          "pulse.min.req" = "84/48000";
          "pulse.default.req" = "84/48000";
          "pulse.max.req" = "84/48000";
          "pulse.min.quantum" = "84/48000";
          "pulse.max.quantum" = "84/48000";
          "server.address" = [ "unix:native" ];
        };
      }
    ];
    "stream.properties" = {
      "node.latency" = "84/48000";
      "resample.quality" = 1;
    };
  };
};


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
   programs.gnupg.agent = {
     enable = true;
  #   enableSSHSupport = true;
     pinentryFlavor = "gtk2";
   };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [];
  networking.firewall.allowedUDPPorts = [];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

  services.xserver.libinput.enable = true;
  
  services.xserver = {
    enable = true;
    displayManager = {
       defaultSession = "none+bspwm";
       lightdm.greeters.mini = {
         enable = true;
         user = "widward";
         extraConfig = ''
           [greeter-theme]
           background-image = "/opt/sanaebg3.png"
           font = terminus 
          '';
       };
    };
  };
  
  # Hardware Accelertation

  hardware.opengl = {
    enable = true;
    extraPackages32 = with pkgs.pkgsi686Linux; [ vaapiIntel ];
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      libvdpau-va-gl
      vaapiIntel
      vaapiVdpau
    ];
  };

  services.xserver.windowManager.dwm.enable = true;

  services.xserver.windowManager.bspwm.enable = true;

  hardware.acpilight.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC="performance";
      CPU_SCALING_GOVERNOR_ON_BAT="powersave";
      CPU_MAX_PERF_ON_AC=100;
      CPU_MAX_PERF_ON_BAT=40;
      INTEL_GPU_MIN_FREQ_ON_AC=0;
      INTEL_GPU_MIN_FREQ_ON_BAT=0;
      INTEL_GPU_MAX_FREQ_ON_AC=100;
      INTEL_GPU_MAX_FREQ_ON_BAT=40;
      INTEL_GPU_BOOST_FREQ_ON_AC=1;
      INTEL_GPU_BOOST_FREQ_ON_BAT=0;

    };
  };

  # OTD

  hardware.opentabletdriver.enable = true;

  # nextdns 

  services.nextdns = {
    enable = true;
    arguments = [ "-config" "10.0.3.0/24=abcdef" "-cache-size" "10MB" ];
  };


  nixpkgs.overlays = [
   (final: prev: {
     dwm = prev.dwm.overrideAttrs (old: { src =/home/widward/widwardDWM/dwm-6.3 ;});
   })
   (final: prev: {
     dmenu = prev.dmenu.overrideAttrs (old: { src =/home/widward/widwardDWM/dmenu-5.1 ;});
   })
#   (final: prev: {
#     st = prev.st.overrideAttrs (old: { src =/home/widward/widwardDWM/st-0.8.5 ;});
#   })
   (final: prev: {
     dwmblocks = prev.dwmblocks.overrideAttrs (old: { src =/home/widward/widwardDWM/dwmblocks ;});
   })
   ];

}
