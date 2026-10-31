set shell := ["bash", "-euo", "pipefail", "-c"]

image := `bash -c 'source config/os.env; echo ${MYOS_ID}'`
owner := env("GHCR_OWNER", "local")

default:
    @just --list

# Build the image locally with podman (needs ~60 GB free)
build variant="":
    #!/usr/bin/env bash
    set -euo pipefail
    source config/os.env
    base="$BASE_IMAGE"; name="$MYOS_ID"
    if [ "{{ variant }}" = "nvidia" ]; then base="ghcr.io/ublue-os/bazzite-gnome-nvidia-open"; name="${MYOS_ID}-nvidia"; fi
    sudo podman build --pull=newer \
        --build-arg BASE_IMAGE="$base" --build-arg BASE_TAG="$BASE_TAG" \
        --build-arg IMAGE_OWNER="{{ owner }}" --build-arg IMAGE_NAME="$name" \
        -t "localhost/$name:latest" .

# Lint every shell script
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    for f in build_files/*.sh system_files/usr/libexec/myos/*.sh; do bash -n "$f"; done
    command -v shellcheck >/dev/null && shellcheck -x -S warning build_files/*.sh system_files/usr/libexec/myos/*.sh || echo "(shellcheck not installed; syntax check only)"

# Build an installer ISO from the local image (output/bootiso/install.iso)
iso variant="":
    #!/usr/bin/env bash
    set -euo pipefail
    source config/os.env
    name="$MYOS_ID"; [ "{{ variant }}" = "nvidia" ] && name="${MYOS_ID}-nvidia"
    mkdir -p output
    sed "s|@IMAGE_REF@|ghcr.io/{{ owner }}/${name}:latest|" disk_config/iso.toml > output/iso.toml
    sudo podman run --rm -it --privileged --pull=newer --security-opt label=type:unconfined_t \
        -v ./output/iso.toml:/config.toml:ro -v ./output:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        --type anaconda-iso --use-librepo=True --local "localhost/${name}:latest"

# Build a qcow2 VM disk from the local image, for quick boot tests
qcow2 variant="":
    #!/usr/bin/env bash
    set -euo pipefail
    source config/os.env
    name="$MYOS_ID"; [ "{{ variant }}" = "nvidia" ] && name="${MYOS_ID}-nvidia"
    mkdir -p output
    sudo podman run --rm -it --privileged --pull=newer --security-opt label=type:unconfined_t \
        -v ./disk_config/disk.toml:/config.toml:ro -v ./output:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        --type qcow2 --local "localhost/${name}:latest"

# Boot the qcow2 in QEMU (UEFI via OVMF, KVM)
run-vm:
    qemu-system-x86_64 -enable-kvm -m 8G -smp 4 -cpu host -machine q35 \
      -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/ovmf/OVMF_CODE.fd \
      -drive file=output/qcow2/disk.qcow2,if=virtio -device virtio-vga-gl -display gtk,gl=on \
      -nic user,model=virtio
