#!/usr/bin/env python
import scipy.signal as signal
import numpy as np

def quantize(x, qf):
   return np.floor(x*pow(2, qf))/pow(2, qf)

n = 2 # filter order
qf = 7 # nb-1
fc = 2e3 # cutoff
fs = 10e3 # sampling freq

# get coefficients in fractional format
sos = quantize(signal.butter(n, 2*fc/fs, 'lowpass', output='sos'), qf)

# test vector
f = [1550, 2500] # frequency components
t = np.arange(0, 256/fs, 1/fs) # time samples

x1 = np.sin(2*np.pi*f[0]*t)
x2 = np.sin(2*np.pi*f[1]*t)

# apply
xq = quantize((x1+x2)/2, qf)
yq = quantize(signal.sosfilt(sos, xq), qf)

# save int
np.savetxt('samples', xq*(pow(2, qf)), fmt="%d")
np.savetxt('results', yq*(pow(2, qf)), fmt="%d")

