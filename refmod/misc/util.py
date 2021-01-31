#!/usr/bin/python3

import numpy as np


def save(fname, data):
    np.savetxt(fname, data, fmt="%d")


def qfrac(x, qf):
    return np.floor(x*pow(2, qf))/pow(2, qf)


def stimuli(freqs, f_sampling, n_samples):

    t = np.arange(0, n_samples/f_sampling, 1/f_sampling)
    sin = 0

    for f in freqs:
        sin += np.sin(2*np.pi*f*t)
        sin /= len(freqs)

    return sin


def look_ahead(d):
    """K. K. Parhi and D. Messerschmitt,
    "Look-ahead computation: Improving iteration bound in linear recursions," ICASSP "87.

    """

    out = np.zeros((d.shape[0], d.shape[1]+2))

    for i in range(d.shape[0]):
        b, a = d[i,:3], d[i,3:]
        out[i,:4] = np.array([b[0], b[1]-a[1]*b[0], b[2]-a[1]*b[1], -a[1]*b[2]])
        out[i,4:] = np.array([a[0], 0, pow(a[1],2)-a[2], -a[1]*a[2]])

    return out


