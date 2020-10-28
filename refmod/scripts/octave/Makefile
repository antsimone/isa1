TGT	= dynrange.m
all:
	@octave --no-gui --no-window-system --eval "pkg load signal; run $(TGT:.m=)"
clean:
	@rm -rf fig/ *.txt *~ results samples

.PHONY: all clean
