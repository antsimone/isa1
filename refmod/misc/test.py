#!/usr/bin/python3

import scipy.signal as signal
import numpy as np

from  util import qfrac, look_ahead

nb = 8
fc = 2e3
fs = 10e3

d = qfrac(signal.butter(2, 2*fc/fs, "lowpass", output="sos"), nb-1)

# get new wordlength that has no round-off noise

d = look_ahead(d)
nb_new = nb
while not np.array_equal(qfrac(d, nb_new-1), d):
   nb_new +=1

print("Coefficients:\t", qfrac(d, nb_new-1))
print("Wordlength:\t", nb_new)
print("", d*(pow(2, nb_new-1)))

