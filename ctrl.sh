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
  local LCL_QEMU_ARGS

  LCL_ARCHIVE_PATH_KERNEL=boot/zImage
  case "${MACHINE}" in
    vexpress-a9)
      LCL_ARCHIVE_PATH_DTB=boot/dtbs/vexpress-v2p-ca9.dtb
      LCL_QEMU_ARGS="${LCL_QEMU_ARGS} -drive file=${FS_IMG},id=rootfs.img,if=sd,format=raw,bus=0,unit=0"
      ;;
    vexpress-a15)
      #vexpress-v2p-ca15_a7.dtb
      #vexpress-v2p-ca15-tc1.dtb
      LCL_ARCHIVE_PATH_DTB=boot/dtbs/vexpress-v2p-ca15_a7.dtb
      LCL_QEMU_ARGS="${LCL_QEMU_ARGS} -drive file=${FS_IMG},id=rootfs.img,if=sd,format=raw,bus=0,unit=0"
      # Doesn't seem to make any difference
      #LCL_QEMU_ARGS="${LCL_QEMU_ARGS} -smp cpus=4"
      ;;
    raspi2)
      echo "${MACHINE} does not work ATM"
      LCL_ARCHIVE_PATH_DTB=boot/dtbs/bcm2836-rpi-2-b.dtb
      LCL_QEMU_ARGS="${LCL_QEMU_ARGS} -sd ${FS_IMG}"
      ;;
    virt)
      echo "${MACHINE} does not work ATM"
      LCL_QEMU_ARGS="${LCL_QEMU_ARGS} -drive file=${FS_IMG},id=rootfs.img,if=sd,format=raw -device virtio-blk-pci,scsi=off,drive=rootfs.img,id=disk0"
      ;;
    *)
      die "Unsupported machine: ${MACHINE}"
      ;;
  esac

  if [ -n "${LCL_ARCHIVE_PATH_DTB}" ]; then
    LCL_QEMU_ARGS="${LCL_QEMU_ARGS} -dtb ${LCL_TMPDIR}/dtb"
  fi

  # Extract the resources
  extract_resources "${FS_IMG}" "${LCL_ARCHIVE_PATH_KERNEL}" "${LCL_ARCHIVE_PATH_DTB}" "${LCL_TMPDIR}"

  # Run QEMU
  qemu-system-arm \
   -machine type="${MACHINE}" \
   -m 1G \
   -kernel "${LCL_TMPDIR}/kernel" \
   ${LCL_QEMU_ARGS} \
   -append "rw console=ttyAMA0,115200 root=/dev/mmcblk0 rootwait" \
   -serial stdio \
   -redir tcp:12022::22 -redir tcp:58080::8080

if false; then
   -sd "${FS_IMG}" \
   -netdev user,id=mynet0,hostfwd=tcp::50022-:22,hostfwd=tcp::58080-:8080 \
   -device virtio-net-device,netdev=mynet0,mac=52:54:00:fa:ce:14
fi

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
