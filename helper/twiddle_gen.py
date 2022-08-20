"""
This is a helper script to generate twiddle factors for the N-point FFT
The twiddle factors generated will be stored in the Q-16 format
"""

import argparse
import math

parser = argparse.ArgumentParser()

parser.add_argument( 
                    "num_points",  
                    help="Number of DFT points => nth roots of unity to generate",
                    type=int)

parser.add_argument("-O",
                    "--overwrite",
                    help = "overwrite old file if there is a name clash",
                    action="store_true")

parser.add_argument("filename",
                        help = "name of file to be written",
                        type = str)

parser.add_argument("Q",
                    help="Fixed point format. E.g for Q-16, 16 will be specified",
                    default=16,
                    type=int)

parser.add_argument("--separate",
                    help = "write different files for real and complex values",
                    action = "store_true")

parser.add_argument("-f,",
                    "--format",
                    help = """number format to write to
                            b -> binary, x->hexadecimal """,
                    type = str,
                    default='b',
                    choices=['x', 'b'])

args = parser.parse_args()

print(args)
if args.format == 'x':
    num_chars = args.Q//4
elif args.format == 'b':
    num_chars = args.Q 

str_mag_format = "{:0" + str(num_chars) +  args.format + "}"
multiplier = 2 ** (args.Q-1) -1


def get_nth_roots_of_unity(N):
    base = math.pi/N 
    for n in range(N):
        yield (math.cos(base *n ), math.sin(base * n))


sign = 2 ** (args.Q-1)


def to_Q_fixed_point(val):
    val = val * multiplier

    # yes, the & is very necessary. You don't want to know jkalklsdfjkl
    val = int(val) & (2**args.Q)-1
    return  str_mag_format.format((val))

with open(args.filename, "w") as f:

    for real_comp, complex_comp in get_nth_roots_of_unity(args.num_points):
        real_comp = to_Q_fixed_point(real_comp)
        complex_comp = to_Q_fixed_point(complex_comp)

        f.write(real_comp + " " + complex_comp + "\n")


