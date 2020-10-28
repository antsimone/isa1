#!/usr/bin/env python

import scipy.signal as signal
import numpy as np

def qfrac(x, qf):
    return np.floor(x*pow(2, qf))/pow(2, qf)

def stimuli(freqs, f_sampling, n_samples):
    t = np.arange(0, n_samples/f_sampling, 1/f_sampling)
    sin = 0
    for f in freqs:
        sin += np.sin(2*np.pi*f*t)
        sin /= len(freqs)
    return sin

def lookahead(sos):
    """Clustered Look-ahead example
       1. yn = xnb0 + xn-1b1 + xn-2b2 - a1yn-1 - a2yn-2
       2. yn-1 = xn-1b0 + xn-2b1 + xn-3b2 - a1yn-2 - a2yn-3
       2 --> 1
       -------
       yn = xnb0 + xn-1[b1 - a1b0] + xn-2[b2 - a1b1] - xn-3[a1b2]
            + yn-2[a1**2 - a2] + yn-3[a1a2])
    """
    sos_new = np.zeros((sos.shape[0], sos.shape[1]+2))
    for i in range(sos.shape[0]):
        b, a = sos[i,:3], sos[i,3:]
        sos_new[i,:4] = np.array([b[0], b[1]-a[1]*b[0], b[2]-a[1]*b[1], -a[1]*b[2]])
        sos_new[i,4:] = np.array([a[0], 0, pow(a[1],2)-a[2], a[1]*a[2]])
    return sos_new


nfilt = 2 # filter order
nb = 8 # wordlength
fc = 2e3 # cutoff
fs = 10e3 # sampling freq

# get coefficients in fractional format
sos = qfrac(signal.butter(nfilt, 2*fc/fs, 'lowpass', output='sos'), nb-1)

# apply
xq = qfrac(stimuli([1300, 2700], 128, fs), nb-1)
yq = qfrac(signal.sosfilt(sos, xq), nb-1)

# save int
np.savetxt('samples', xq*(pow(2, nb-1)), fmt="%d")
np.savetxt('results', yq*(pow(2, nb-1)), fmt="%d")

# get new wordlength that has no round-off noise
sos_new = lookahead(sos)
while not np.array_equal(qfrac(sos_new, nb-1), sos_new): 
    nb +=1
print(nb)
print(sos_new*(pow(2, nb-1)))
np.savetxt('results_la', sos_new*(pow(2, nb-1)), fmt="%d")
