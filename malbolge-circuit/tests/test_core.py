"""Independent reference checks for ternary core; Python is test-only, not runtime/IR."""
import random

N = 59049
TABLE = ((1, 0, 0), (1, 0, 2), (2, 2, 1))  # [memory trit][accumulator trit]

def crazy(a, d):
    assert 0 <= a < N and 0 <= d < N
    result, factor = 0, 1
    for _ in range(10):
        result += factor * TABLE[d % 3][a % 3]
        a //= 3
        d //= 3
        factor *= 3
    return result

def rotate(x):
    assert 0 <= x < N
    return x // 3 + (x % 3) * 19683

def check():
    for d in range(3):
        for a in range(3):
            assert crazy(a, d) % 3 == TABLE[d][a]
    for x in range(N):
        assert 0 <= rotate(x) < N
        assert rotate(rotate(rotate(rotate(rotate(rotate(rotate(rotate(rotate(rotate(x)))))))))) == x
        assert crazy(x, 0) < N
    rng = random.Random(3301)
    for _ in range(10000):
        a, d = rng.randrange(N), rng.randrange(N)
        r = crazy(a, d)
        assert 0 <= r < N
        assert r == sum(TABLE[(d // 3**i)%3][(a // 3**i)%3]*3**i for i in range(10))
    print('PASS: 9 trit pairs; 59049 rotations and range checks; 10000 crazy-word samples')

if __name__ == '__main__':
    check()
