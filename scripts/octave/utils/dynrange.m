close
clc all
clear all

% default property setup
set(groot, 'defaultLineLinewidth', 1.5);
set(groot, 'defaultAxesFontSize', 14);

% Filte config
Nf = 2; % filter order 
fc = 2e3; % cutoff frequency
fs = 1e4; % sampling frequency

% Fixed-point 
Nb = 8; % word length
Qf = 7; % fractional bits

lsb = 2^Qf;
msb = 2^(Nb-Qf-1);
max_value = msb-(1/lsb);
min_value = -msb;

disp(sprintf('\n'))

disp(sprintf('Filter Order:\n\n\t%8d\n', Nf))
disp(sprintf('Filter WordLength:\n\n\t%8d\n', Nb))
disp(sprintf('MinValue:\n\n\t%8d\n', min_value))
disp(sprintf('MaxValue:\n\n\t%8d\n', max_value))

% Get filter iir_coefficients
[~,~,b,a] = iir_coeff(Nf, fc, fs, Nb);

% Transfer functions
sys = tf(b, a, 1/fs)
sys_ff = tf(sys.Num, [0 0 1], 1/fs)
sys_fb = tf([0 0 1], sys.Den, 1/fs)
sys_fb_t = tf(cell2mat(sys_fb.Den)(2:end),
                    cell2mat(sys_fb.Num), 1/fs)

% node 2 gain
disp(sprintf('\nFilter output'))
[h] = impz(cell2mat(sys.Num), cell2mat(sys.Den)); h
% L2 norm
g_l2_norm = sum(abs(h.^2))^(1/2)
g_l1_norm = sum(abs(h))

% Recursive part (node 1 gain)
disp(sprintf('\nRecursive part'))
[h] = impz(cell2mat(sys_fb.Num), cell2mat(sys_fb.Den))
% L norm
g_l2_norm = sum(abs(h.^2))^(1/2)
g_l1_norm = sum(abs(h))

disp(sprintf('\nRecursive part step response'))
[h] = step(sys_fb)

% Forward part (fir) (node 2 gain)
disp(sprintf('\nFeedforward part'))
[h] = impz(cell2mat(sys_ff.Num), cell2mat(sys_ff.Den))
% L norm
g_l2_norm = sum(abs(h.^2))^(1/2)
g_l1_norm = sum(abs(h))

% sum fb taps
disp(sprintf('\nFb taps'))
[h] = impz(cell2mat(sys_fb_t.Num), cell2mat(sys_fb_t.Den));
% L norm
g_l2_norm = sum(abs(h.^2))^(1/2)
g_l1_norm = sum(abs(h))

% Filter ex 100 samples (random)
Nx = 100;
y = zeros(Nx+2); 
x = [0 0 (rand(1, Nx)-0.5)*2];
d = zeros(Nx+2); 
% Loop on input samples with offset 3
for n = 3:Nx+2 
  d(n) = (x(n) - a(2)*d(n-1) - a(3)*d(n-2));
  y(n) = (b(1)*d(n) + b(2)*d(n-1) + b(3)*d(n-2));
end
max(d(:,1))

% Worst-case analysis (step)
x = ones(Nx+2);
d = zeros(Nx+2); 
% Loop on input samples with offset 3
for n = 3:Nx+2 
  d(n) = (x(n) - a(2)*d(n-1) - a(3)*d(n-2));
  y(n) = (b(1)*d(n) + b(2)*d(n-1) + b(3)*d(n-2));
end
disp([ 'max value = ' num2str(max(d(:,1)))       



