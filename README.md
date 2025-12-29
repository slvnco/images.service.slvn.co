# images.service.slvn.co

## Images

### Trixie (13)

- [cloud/trixie/slvn-debian-trixie-bios-cloud-latest](https://images.service.silvenga.com/images/cloud/trixie/slvn-debian-trixie-bios-cloud-latest.img)
- [live/trixie/slvn-debian-trixie-live-latest](https://images.service.silvenga.com/images/live/trixie/slvn-debian-trixie-live-latest.iso)

### Bookworm (12)

- [cloud/bookworm/slvn-debian-bookworm-bios-cloud-latest](https://images.service.silvenga.com/images/cloud/bookworm/slvn-debian-bookworm-bios-cloud-latest.img)
- [live/bookworm/slvn-debian-bookworm-live-latest](https://images.service.silvenga.com/images/live/bookworm/slvn-debian-bookworm-live-latest.iso)

## Dependencies

```bash
apt-get install debootstrap arch-install-scripts qemu-utils libguestfs-tools
```

## Building

```bash
make cloud
make live
```
