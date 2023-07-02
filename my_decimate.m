%
% Function to decimate signal for correlation processing
% Applies anti-aliasing filter then downsamples
%
function decimated_signal = my_decimate(signal, decimation)
     % To avoid spectrum aliasing, the cutoff frequency of the lowpass
     % filter should be at most 1/R. Where R is the decimation factor
     f_cutoff_normalized = 0.8/decimation;
     % Filter and downsample
     filtered_signal = my_lowpass(signal, 500, f_cutoff_normalized);
     decimated_signal = filtered_signal(1:decimation:end);
 end