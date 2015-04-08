Facter.add(:dpkg_arch) do
  confine :kernel => :linux
  confine :osfamily => :Debian
  setcode do
    arch = Facter::Util::Resolution.exec('dpkg --print-architecture')
    arch
  end
end

Facter.add(:dpkg) do
  confine :kernel => :linux
  confine :osfamily => :Debian
  dpkg = {}
  setcode do
    arch = Facter::Util::Resolution.exec('dpkg --print-architecture')
    dpkg['architecture'] = arch
    dpkg
  end
end
