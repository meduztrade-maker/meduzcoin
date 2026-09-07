import itertools
from Crypto.Hash import keccak

ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
ENC_BLOCK_SIZES = [0, 2, 3, 5, 6, 7, 9, 10, 11]
FULL_BLOCK = 8
FULL_ENC = 11

def varint(n):
    out = bytearray()
    while True:
        b = n & 0x7f
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            break
    return bytes(out)

def encode_block(block, size):
    num = int.from_bytes(block, 'big')
    enc_size = ENC_BLOCK_SIZES[size]
    res = [ALPHABET[0]] * enc_size
    i = enc_size - 1
    while num > 0:
        num, rem = divmod(num, 58)
        res[i] = ALPHABET[rem]
        i -= 1
    return ''.join(res)

def encode(data: bytes):
    full_blocks = len(data) // FULL_BLOCK
    last_size = len(data) % FULL_BLOCK
    out = ''
    for i in range(full_blocks):
        out += encode_block(data[i*FULL_BLOCK:(i+1)*FULL_BLOCK], FULL_BLOCK)
    if last_size:
        out += encode_block(data[full_blocks*FULL_BLOCK:], last_size)
    return out

def cn_fast_hash(data: bytes) -> bytes:
    k = keccak.new(digest_bits=256)
    k.update(data)
    return k.digest()

def make_address(tag: int, spend_pub: bytes, view_pub: bytes) -> str:
    buf = varint(tag) + spend_pub + view_pub
    h = cn_fast_hash(buf)
    buf += h[:4]
    return encode(buf)

def deterministic_prefix(tag: int) -> str:
    v = varint(tag)
    if len(v) >= FULL_BLOCK:
        return ""  # too big, degenerate
    pad = FULL_BLOCK - len(v)
    block_min = v + b'\x00' * pad
    block_max = v + b'\xff' * pad
    a = encode_block(block_min, FULL_BLOCK)
    b = encode_block(block_max, FULL_BLOCK)
    common = 0
    for x, y in zip(a, b):
        if x == y:
            common += 1
        else:
            break
    return a[:common]

# Search a wide range of tag values, keep ones with a decent stable prefix
candidates = []
for tag in range(1, 3_000_000):
    p = deterministic_prefix(tag)
    if len(p) >= 3:
        candidates.append((tag, p))

print(f"Total candidates with >=3 stable chars: {len(candidates)}")

# Look for ones starting with letters relevant to MEDUZ brand
targets = ["MED", "MDZ", "MDU", "MEZ", "MDZ", "MZ", "MD"]
for tag, p in candidates:
    up = p.upper()
    for t in targets:
        if up.startswith(t):
            print(tag, p)
            break
