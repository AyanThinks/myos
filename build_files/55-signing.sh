#!/usr/bin/bash
# Installs your cosign public key + container policy so the image can verify its own signatures.
source "$CTX/build_files/lib.sh"
KEY="$CTX/config/signing/cosign.pub"
if [ ! -f "$KEY" ] || [ -z "${IMAGE_OWNER:-}" ] || [ -z "${IMAGE_NAME:-}" ]; then
    log "No signing key / owner / image name supplied: skipping signature policy (image will be unsigned)."
    exit 0
fi
install -d /etc/pki/containers /etc/containers/registries.d
install -m 0644 "$KEY" "/etc/pki/containers/${MYOS_ID}.pub"
cat > "/etc/containers/registries.d/${MYOS_ID}.yaml" <<YEOF
docker:
  ghcr.io/${IMAGE_OWNER}:
    use-sigstore-attachments: true
YEOF
POL=/etc/containers/policy.json
[ -f "$POL" ] || { echo '{"default":[{"type":"insecureAcceptAnything"}],"transports":{"docker-daemon":{"":[{"type":"insecureAcceptAnything"}]}}}' > "$POL"; }
tmp="$(mktemp)"
jq --arg img "ghcr.io/${IMAGE_OWNER}/${IMAGE_NAME}" --arg key "/etc/pki/containers/${MYOS_ID}.pub" \
   '.transports.docker = (.transports.docker // {}) | .transports.docker[$img] = [{"type":"sigstoreSigned","keyPath":$key,"signedIdentity":{"type":"matchRepository"}}]' \
   "$POL" > "$tmp"
install -m 0644 "$tmp" "$POL"; rm -f "$tmp"
log "Signature policy installed for ghcr.io/${IMAGE_OWNER}/${IMAGE_NAME}"
