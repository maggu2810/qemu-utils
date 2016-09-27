#!/bin/sh

MY_CMD="${0}"
MY_DIR_REL="`dirname "${MY_CMD}"`"
MY_DIR_ABS="$(cd "${MY_DIR_REL}"; echo ${PWD})"

MACHINE=vexpress-a9


die() {
  if [ "${#}" -gt 0 ]; then
    echo "${@}"
  fi
  exit 1
}

extract_resources() {
  local FS_IMG="${1}"; shift
  local ARCHIVE_PATH_KERNEL="${1}"; shift
  local ARCHIVE_PATH_DTB="${1}"; shift
  local DST_DIR="${1}"; shift

  local TMPDIR="`mktemp -d`"

  sudo mount -o loop "${FS_IMG}" "${TMPDIR}"
  cp -v "${TMPDIR}/${ARCHIVE_PATH_KERNEL}" "${DST_DIR}"/kernel
  cp -v "${TMPDIR}/${ARCHIVE_PATH_DTB}" "${DST_DIR}"/dtb
  sudo umount "${TMPDIR}"
  rmdir "${TMPDIR}"
}

run() {
  local TMPDIR="`mktemp -d`"

  # Extract the resources
  extract_resources "${FS_IMG}" "${ARCHIVE_PATH_KERNEL}" "${ARCHIVE_PATH_DTB}" "${TMPDIR}"

  # Run QEMU
  qemu-system-arm \
   -machine type="${MACHINE}" \
   -smp cpus=1 \
   -m 1G \
   -sd "${FS_IMG}" \
   -kernel "${TMPDIR}/kernel" \
   -dtb "${TMPDIR}/dtb" \
   -append "rw console=ttyAMA0,115200 root=/dev/mmcblk0" \
   -serial stdio \
   -redir tcp:12022::22

  rm -rf "${TMPDIR}"
}

case "${MACHINE}" in
  vexpress-a9)
    ARCHIVE_PATH_KERNEL=boot/zImage
    ARCHIVE_PATH_DTB=boot/dtbs/vexpress-v2p-ca9.dtb
    ;;
  *)
    die "Unsupported machine"
    ;;
esac

FS_IMG="${MY_DIR_ABS}"/armv7.ext4
run
