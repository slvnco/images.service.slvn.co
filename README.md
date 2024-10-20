# images.service.slvn.co

## Images

- [cloud/slvn-debian-bookworm-uefi-cloud-latest](https://images.service.silvenga.com/images/cloud/slvn-debian-bookworm-uefi-cloud-latest.img)
- [live/slvn-debian-bookworm-live-latest](https://images.service.silvenga.com/images/live/slvn-debian-bookworm-live-latest.iso)

## Dependencies

```bash
apt-get install debootstrap arch-install-scripts qemu-utils libguestfs-tools
```

## Building

```bash
make cloud
make live
```
