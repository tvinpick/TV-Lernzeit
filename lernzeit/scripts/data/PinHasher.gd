class_name PinHasher
extends RefCounted
## PIN storage helper: the PIN is never stored in plain text.
## Stored value = SHA-256 iterated ROUNDS times over (salt + pin), hex encoded,
## with an individual random 16-byte salt per installation / PIN change.

const ROUNDS := 20000
const PIN_LENGTH := 4


static func new_salt() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


static func hash_pin(pin: String, salt_hex: String) -> String:
	var data := (salt_hex + ":" + pin).to_utf8_buffer()
	var digest := data
	for i in ROUNDS:
		var ctx := HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256)
		ctx.update(digest)
		ctx.update(data)
		digest = ctx.finish()
	return digest.hex_encode()


static func is_valid_pin(pin: String) -> bool:
	return pin.length() == PIN_LENGTH and pin.is_valid_int() and not pin.contains("-") and not pin.contains("+")


## Length-independent comparison of two hex strings.
static func equals(a: String, b: String) -> bool:
	if a.length() != b.length():
		return false
	var diff := 0
	for i in a.length():
		diff |= a.unicode_at(i) ^ b.unicode_at(i)
	return diff == 0
