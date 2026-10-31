# Image signing key (optional but recommended)

1. `cosign generate-key-pair` (leave the password empty, or add it as a secret too).
2. Commit the **public** key here as `config/signing/cosign.pub`.
3. Add the **private** key (`cosign.key` contents) as a GitHub Actions secret named `SIGNING_SECRET`.

When `cosign.pub` exists, the image build installs it plus a container-policy entry so
`rpm-ostree`/`bootc` can verify signatures of your image. Without it, builds and installs
still work; they are simply unsigned. NEVER commit `cosign.key`.
