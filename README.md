# YubiKey Invalidation

[YubiKeys](https://www.yubico.com/products/yubikey-hardware/yubikey/) are
pretty cool, but some models (e.g., Nano) are easy to accidentally set off.

This plugin watches for YubiKey strings and sends them off for "validation"
when it sees them, which has the effect of invalidating them.

## Configuration

* `HUBOT_YUBIKEY_API_ID`: API ID (the numeric one) from
  <https://upgrade.yubico.com/getapikey/>
