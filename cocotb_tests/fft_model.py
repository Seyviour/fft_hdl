import numpy as np
import math

def get_nth_roots_of_unity(N):
    divisions = np.array([ -2 * n * 1j* np.pi/N for n in range (N)])
    roots = np.exp(divisions)
    print(roots)
    return roots

def permute_zerod(x):
    m = 0
    N = len(x)
    i = 0
    for n in range(N):
        if n > i:
            x[i], x[n] = x[n], x[i]

        m = N//2
        while m >=2 and i >= m:
            i -= m
            m //= 2
        i += m 
    
    return x

tw = get_nth_roots_of_unity(32) * 32768

Tw_r = [int(x.real) for x in tw]
Tw_i = [int(x.imag) for x in tw]

print(Tw_r)
print(Tw_i)


print("datar")

data_r = permute_zerod([x for x in range(32)])
# data_r = permute_zerod([int(math.cos(x) * 30) for x in range(32)])
data_i = permute_zerod([x for x in range(32)])

print(data_r)
print(data_i)


for i in range(5):
    for j in range(16):

        ja = j << 1
        jb = ja + 1
        ja = ((ja << i) | (ja >> (5-i))) & 0x1f
        jb = ((jb << i) | (jb >> (5-i))) & 0x1f

        TwAddr = (( 0xfffffff0 >> i ) & 0xf ) & j

        print(ja, jb, TwAddr)

        temp_r = ((data_r[jb] * Tw_r[TwAddr]) >> 15) - ((data_i[jb] * Tw_i[TwAddr])>>15)
        temp_i = ((data_r[jb] * Tw_i[TwAddr]) >>15) + ((data_i[jb] * Tw_r[TwAddr])>>15)

        data_r[jb] = data_r[ja] - temp_r
        data_i[jb] = data_i[ja] - temp_i

        data_r[ja] += temp_r
        data_i[ja] += temp_i

    print(data_r)
    print("\n")
    print(data_i)
    print("\n")
    print("\n")

# import numpy as np

# a = np.fft.fft(np.array([x for x in range (32)]))
# print(a)
        
# f = [complex(a, b) for a, b in zip(data_r, data_i)]
# f = np.fft.ifft(f)
# print(f)

# a = np.fft.ifft(a)
# print(a)


def DFT_slow(x):
    """compute the DFT of the 1D array x"""
    x = np.asarray(x, dtype=float)
    N = x.shape[0]
    n = np.arange(N)
    k = n.reshape((N,1))
    M = np.exp(-2j * np.pi * k * n /N)
    return np.dot(M, x)

