#!/bin/sh

MY_CMD="${0}"
MY_DIR_REL="`dirname "${MY_CMD}"`"
MY_DIR_ABS="$(cd "${MY_DIR_REL}"; echo ${PWD})"

MACHINE=vexpress-a9
FS_IMG="${MY_DIR_ABS}"/armv7.ext4

die() {
  if [ "${#}" -gt 0 ]; then
    echo "${@}"
  fi
  exit 1
}

#
# We rely on the following global environment variables:
# * FS_IMG
#
my_cmd_create_img() {
  local LCL_FS_IMG="${FS_IMG}"

  local LCL_TMPDIR="`mktemp -d`"
  local LCL_PATH_DL="${LCL_TMPDIR}/image.tgz"
  local LCL_PATH_MP="${LCL_TMPDIR}/mnt"

  # Fetch an Arch Linux ARMv7 rootfs
  wget -O "${LCL_PATH_DL}" "http://www.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz"

  # Create a image to put root fs content into
  qemu-img create "${LCL_FS_IMG}" 4G

  # Create FS for image
  /sbin/mkfs.ext4 "${LCL_FS_IMG}"

  # Now fill the FS image with content
  mkdir "${LCL_PATH_MP}"
  sudo mount -o loop "${LCL_FS_IMG}" "${LCL_PATH_MP}"
  sudo bsdtar -xpf "${LCL_PATH_DL}" -C "${LCL_PATH_MP}"
  sudo umount "${LCL_PATH_MP}"
  rmdir "${LCL_PATH_MP}"

  # Now you can remove the downloaded archive.
  rm "${LCL_PATH_DL}"

  # Remove TMP directory
  rmdir "${LCL_TMPDIR}"
}


#
# We don't rely on any global environment variables
#
extract_resources() {
  local LCL_FS_IMG="${1}"; shift
  local LCL_ARCHIVE_PATH_KERNEL="${1}"; shift
  local LCL_ARCHIVE_PATH_DTB="${1}"; shift
  local LCL_DST_DIR="${1}"; shift

  local LCL_TMPDIR="`mktemp -d`"

  sudo mount -o loop "${LCL_FS_IMG}" "${LCL_TMPDIR}"
  cp -v "${LCL_TMPDIR}/${LCL_ARCHIVE_PATH_KERNEL}" "${LCL_DST_DIR}"/kernel
  cp -v "${LCL_TMPDIR}/${LCL_ARCHIVE_PATH_DTB}" "${LCL_DST_DIR}"/dtb
  sudo umount "${LCL_TMPDIR}"
  rmdir "${LCL_TMPDIR}"
}

#
# We rely on the following global environment variables:
# * FS_IMG
# * MACHINE
#
my_cmd_run() {
  local LCL_TMPDIR="`mktemp -d`"

  local LCL_ARCHIVE_PATH_KERNEL
  local LCL_ARCHIVE_PATH_DTB
  case "${MACHINE}" in
    vexpress-a9)
      LCL_ARCHIVE_PATH_KERNEL=boot/zImage
      LCL_ARCHIVE_PATH_DTB=boot/dtbs/vexpress-v2p-ca9.dtb
      ;;
    *)
      die "Unsupported machine"
      ;;
  esac

  # Extract the resources
  extract_resources "${FS_IMG}" "${LCL_ARCHIVE_PATH_KERNEL}" "${LCL_ARCHIVE_PATH_DTB}" "${LCL_TMPDIR}"

  # Run QEMU
  qemu-system-arm \
   -machine type="${MACHINE}" \
   -smp cpus=1 \
   -m 1G \
   -sd "${FS_IMG}" \
   -kernel "${LCL_TMPDIR}/kernel" \
   -dtb "${LCL_TMPDIR}/dtb" \
   -append "rw console=ttyAMA0,115200 root=/dev/mmcblk0" \
   -serial stdio \
   -netdev user,id=mynet0,hostfwd=tcp::50022-:22,hostfwd=tcp::58080-:8080 \
   -device virtio-net-device,netdev=mynet0,mac=52:54:00:fa:ce:14

  rm -rf "${LCL_TMPDIR}"
}

my_cmd_ssh() {
  ssh -lalarm -p50022 127.0.0.1
}

#
# Handle command line arguments
#
while [ "${#}" -gt 0 ]; do
  my_cmd_"${1}"; shift
done
