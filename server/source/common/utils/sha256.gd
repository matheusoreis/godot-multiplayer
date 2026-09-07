extends RefCounted
class_name Sha256


const SEPARATOR: String = ":"
const SALT_LENGTH: int = 32
const ITERATIONS: int = 10_000


func hash_value(value: String) -> String:
	var crypto: Crypto = Crypto.new()

	var salt_bytes: PackedByteArray = crypto.generate_random_bytes(SALT_LENGTH)

	var salt_hex: String = salt_bytes.hex_encode()
	var hash_hex: String = _stretch(salt_hex, value)

	return salt_hex + SEPARATOR + hash_hex


func verify_value(value: String, stored_value: String) -> bool:
	if SEPARATOR not in stored_value:
		return false

	var parts: PackedStringArray = stored_value.split(SEPARATOR)
	if parts.size() != 2:
		return false

	var salt_hex: String = parts[0]
	var original_hash: String = parts[1]

	if salt_hex.length() != SALT_LENGTH * 2:
		return false

	var current_hash: String = _stretch(salt_hex, value)
	return _constant_time_equals(current_hash, original_hash)


func is_valid_hash(hash_string: String) -> bool:
	if SEPARATOR not in hash_string:
		return false

	var parts: PackedStringArray = hash_string.split(SEPARATOR)
	if parts.size() != 2:
		return false

	var salt_hex: String = parts[0]
	var hash_hex: String = parts[1]

	if salt_hex.length() != SALT_LENGTH * 2:
		return false

	if hash_hex.length() != 64:
		return false

	return true


func _stretch(salt_hex: String, value: String) -> String:
	var result: String = (salt_hex + value).sha256_text()
	for i in range(ITERATIONS - 1):
		result = (salt_hex + result).sha256_text()
	return result


func _constant_time_equals(a: String, b: String) -> bool:
	if a.length() != b.length():
		return false

	var result: int = 0
	for i in range(a.length()):
		result |= a.unicode_at(i) ^ b.unicode_at(i)

	return result == 0
