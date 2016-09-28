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
  local LCL_DST_DIR="${1}"; shift
  local LCL_FS_IMG="${1}"; shift

  local LCL_DST
  local LCL_SRC

  local LCL_TMPDIR="`mktemp -d`"

  sudo mount -o loop "${LCL_FS_IMG}" "${LCL_TMPDIR}"
  while [ "${#}" -gt 0 ]; do
    LCL_DST="${1}"; shift
    LCL_SRC="${1}"; shift
    if [ -n "${LCL_DST}" -a -n "${LCL_SRC}" ]; then
      cp -v "${LCL_TMPDIR}/${LCL_SRC}" "${LCL_DST_DIR}/${LCL_DST}"
    fi
  done
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
      # Extract the resources
      extract_resources "${LCL_TMPDIR}" "${FS_IMG}" \
        kernel "${LCL_ARCHIVE_PATH_KERNEL}" \
        dtb boot/dtbs/vexpress-v2p-ca9.dtb

      # Run QEMU
      qemu-system-arm \
       -machine type="${MACHINE}" \
       -m 1G \
       -drive file="${FS_IMG}",id=rootfs.img,if=sd,format=raw,bus=0,unit=0 \
       -kernel "${LCL_TMPDIR}/kernel" \
       -dtb "${LCL_TMPDIR}/dtb" \
       -append "rw console=ttyAMA0,115200 root=/dev/mmcblk0" \
       -serial stdio \
       -netdev user,id=mynet0,hostfwd=tcp::50022-:22,hostfwd=tcp::58080-:8080 \
       -device virtio-net-device,netdev=mynet0,mac=52:54:00:fa:ce:14

      # This doesn't seem to work
       #-smp cpus=4 -cpu cortex-a9 \
      ;;
    vexpress-a15)
      # vexpress-v2p-ca15_a7.dtb OR vexpress-v2p-ca15-tc1.dtb

      # Extract the resources
      extract_resources "${LCL_TMPDIR}" "${FS_IMG}" \
        kernel "${LCL_ARCHIVE_PATH_KERNEL}" \
        dtb boot/dtbs/vexpress-v2p-ca15_a7.dtb

      # Run QEMU
      qemu-system-arm \
       -machine type="${MACHINE}" \
       -smp cpus=1 \
       -m 1G \
       -drive file="${FS_IMG}",id=rootfs.img,if=sd,format=raw,bus=0,unit=0 \
       -kernel "${LCL_TMPDIR}/kernel" \
       -dtb "${LCL_TMPDIR}/dtb" \
       -append "rw console=ttyAMA0,115200 root=/dev/mmcblk0" \
       -serial stdio \
       -netdev user,id=mynet0,hostfwd=tcp::50022-:22,hostfwd=tcp::58080-:8080 \
       -device virtio-net-device,netdev=mynet0,mac=52:54:00:fa:ce:14

      # Doesn't seem to make any difference
      # -smp cpus=4
      ;;
    raspi2)
      echo "${MACHINE} does not work ATM"

      # Extract the resources
      extract_resources "${LCL_TMPDIR}" "${FS_IMG}" \
        kernel "${LCL_ARCHIVE_PATH_KERNEL}" \
        dtb boot/dtbs/bcm2836-rpi-2-b.dtb

      # Run QEMU
      qemu-system-arm \
       -machine type="${MACHINE}" \
       -smp cpus=1 \
       -m 1G \
       -drive file="${FS_IMG}",id=rootfs.img,if=sd,format=raw,bus=0,unit=0 \
       -kernel "${LCL_TMPDIR}/kernel" \
       -dtb "${LCL_TMPDIR}/dtb" \
       -append "rw console=ttyAMA0,115200 root=/dev/mmcblk0" \
       -serial stdio \
       -redir tcp:12022::22 -redir tcp:58080::8080
      ;;
    sabrelite)
      echo "${MACHINE} does not work ATM"

      # Extract the resources
      extract_resources "${LCL_TMPDIR}" "${FS_IMG}" \
        kernel "${LCL_ARCHIVE_PATH_KERNEL}" \
        dtb boot/dtbs/imx6q-sabrelite.dtb

      # Run QEMU
      qemu-system-arm \
       -machine type="${MACHINE}" \
       -smp cpus=1 \
       -m 1G \
       -drive file="${FS_IMG}",id=rootfs.img,if=sd,format=raw,bus=0,unit=0 \
       -kernel "${LCL_TMPDIR}/kernel" \
       -dtb "${LCL_TMPDIR}/dtb" \
       -append "rw console=ttyAMA0,115200 root=/dev/mmcblk0" \
       -serial stdio \
       -redir tcp:12022::22 -redir tcp:58080::8080
      ;;
    virt)
      echo "${MACHINE} does not work ATM"
      LCL_QEMU_ARGS="${LCL_QEMU_ARGS} "\
        "-drive file=${FS_IMG},id=rootfs.img,if=sd,format=raw " \
        "-device virtio-blk-pci,drive=rootfs.img,id=disk0" \
        "-device virtio-blk-device,drive=rootfs.img,id=disk1" \
        "-device virtio-scsi-pci,drive=rootfs.img,id=disk2" \
        "-device virtio-scsi-device,drive=rootfs.img,id=disk3" \
        "-device ide-hd,drive=rootfs.img,id=disk4" \
        "-device scsi-hd,drive=rootfs.img,id=disk5" \
        ""
      ;;
    *)
      die "Unsupported machine: ${MACHINE}"
      ;;
  esac

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
