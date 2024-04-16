clear; close all; clc;
%addpath('../folder_x/');

% Input : Which data to load and use from what channel
chann_no = -1;
switch(chann_no)
    case -1
        radio_station = 'FM France 96_9.dat';
        fileID = fopen('96_9.dat', 'r');
        fc = 96.9e6;
    case 0
        radio_station = '93.3 MHz';
        fileID = fopen('93_3.dat', 'r');
        fc = 93.3e6;
    case 1
        radio_station = '100.5 MHz';
        fileID = fopen('100_5.dat','r');
        fc = 100.5e6;
    case 2
        radio_station = '102.7 MHz';
        fileID = fopen('102_7.dat','r');
        fc = 102.7e6;
    case 3
        radio_station = '104.1 MHz';
        fileID = fopen('104_1.dat','r');
        fc = 104.1e6;
end 
% Load the data from the file.
[data_0, count] = fread(fileID);
c = 3e8; % Speed of light m/s
lambda = c/fc; % Wavelength of signal at center frequency
Fs = 2.4e6; % sampling frequency
T = 1.0; % Seconds for cpi
cpi = T*Fs*2;% CPI in samples. Multiply by 2 because 2 samples will be combined into one complex sample
num_steps = 30; % Number of CPI Steps
BWs_list = zeros(1,num_steps); % List of 3db bandwidths

% inc: How many cpis to run
for inc = 1:5
    % Take CPI worth of data from data_0 
    data = data_0(1+(inc-1)*cpi:cpi+(inc-1)*cpi);

    % Separate Interleaved Char Data
    real_data = data(1:2:end);
    complex_data = data(2:2:end);
    % Construct complex signal from data
    complex_signal = real_data + 1i*complex_data;
    complex_signal = complex_signal - mean(complex_signal);

    % Filter to remove waveforms outside of the channel
    complex_signal = my_lowpass(complex_signal, 50, 0.4);

    % Frequency vector
    N = length(complex_signal);
    f = (-(N/2):(N/2-1)) * (Fs/N);
    
    % Take FFT of complex signal and normalize, then plot
    complex_signal_fft_normalized = plot_fft_station(complex_signal, f, radio_station);

    % Plot the Cross-Correlation:
    figure(3);
    plot_xcorr(complex_signal, Fs, radio_station)

    % Calculate 3dB bandwidth.
    BW_3db = calc_3db_bw(f, complex_signal_fft_normalized);

    % Save each bandwidth in a list
    BWs_list(inc) = BW_3db;
    fprintf('3dB Bandwidth: %.2f Hz\n', BW_3db);
    time = 1/Fs * length(complex_signal);
    BT = BW_3db * time;
    BTdb = mag2db(BT);
    
    % Decimate the signal by 1/8 to make it easier to process
    decimation = 8;
    complex_signal = my_decimate(complex_signal, decimation);
    Fs_d = Fs/decimation; % New downsampled sample frequency

    % Signal Setup, 
    xr = complex_signal;
    % 
    d = 30; % Delay in samples;
    f_d = -50; % Doppler shift in Hz;
    t = (0:1/Fs_d:T-1/Fs_d).'; % Time vector
    xr_delayed = [zeros(d, 1); xr(1:end-d)]; % Delay
    xr_doppler = xr_delayed .* exp(1i*2*pi*f_d*t); % Doppler shift
    attenuation = 0.3;
    xe = xr + xr_doppler*attenuation; 

    %%%
    %%% Perform clutter filtering on data
    %%%    
    % Least Squares Matrix Solution
    N = length(xe) - 1;
    M = 200; % Order of least squares filter
    % Create X_e and X_r for least squares matrix solution
    X_e = xe;
    X_r = zeros(N+1, M+1);
    for n = 1:N+1
        if n > M+1
            X_r(n, :) = xr(n-1:-1:n-M-1); 
        else
            X_r(n, 1:n) = xr(n:-1:1);
        end
    end

    % Perform least squares regression for delays using lsqr
    tol = 1e-2; % Tolerance
    maxit = 400; % Maximum number of iterations
    Cs = lsqr(X_r, X_e, tol, maxit);
    % Estimate clutter
    clutter_est = X_r * Cs;
    % Remove clutter from the surveillance signal
    xe_clean = X_e - clutter_est;
    
    %}
 % Get cross ambiguity function and plot it:
    max_lag = 100;
    % Plot Self-Ambiguity Function
    psi_self = cross_ambiguity(xr, xr, max_lag, Fs_d, lambda, inc, 10);
    title(['Self Ambiguity Function for Channel ' num2str(radio_station)]);
    caxis([50 100]);
    xlim([-150 250]);
    ylim([0 40]);
    % Plot Cross Ambiguity Function without Least Squares Clutter Filtering
    psi_1 = cross_ambiguity(xr, xe, max_lag, Fs_d, lambda, inc, 11);
    title(['Cross Ambiguity Function for Channel ' num2str(radio_station) ' for \alpha = ' num2str(attenuation)]);
    caxis([50 100]);
    xlim([-150 250]);
    ylim([0 40]);
    % Plot Cross Ambiguity Function with Least Squares Clutter Filtering
    psi_2 = cross_ambiguity(xr, xe_clean, max_lag, Fs_d, lambda, inc, 12);
    title(['Cross Ambiguity Function for Channel ' num2str(radio_station) ' with Clutter Filtering for \alpha = ' num2str(attenuation)]);
    caxis([85 100]);
    xlim([-150 250]);
    ylim([0 40]);

end
% Plot the bandwidths over each interval
figure(13);
plot((1:num_steps)*seconds, BWs_list/1000); 
title(['Bandwidth Over Time for Channel ' num2str(radio_station)]);
xlabel('Time (seconds)');
ylabel('Bandwidth (kHz)');

function BW_3db = calc_3db_bw(f, complex_signal_fft_normalized)
    % First calculate power in signal
    power_signal_fft = (complex_signal_fft_normalized).^2;
    % Then calculate peak spectral power
    peak_power = max(power_signal_fft); % Should be 1
    peak_power_db = mag2db(power_signal_fft);
    % Find lower and upper frequencies of -3dB
    f_lower = f(find(peak_power_db >= -3, 1, 'first'))
    f_upper = f(find(peak_power_db >= -3, 1, 'last'))
    BW_3db = (f_upper - f_lower);
end

function plot_xcorr(complex_signal, Fs, radio_station)
    [R, lags] = xcorr(complex_signal);
    R_normalized = abs(R)/max(abs(R));
    plot(lags/Fs*1e6, mag2db(R_normalized))
    
    title(['Autocorrelation of the Complex Signal for Station ' radio_station]);
    xlabel('Lag (\mus)');
    ylabel('|R(\tau)| (dB)')
    ylim([-60, 10])
    xlim([-100 100])
end 

% Plots the FFT for a radio station signal  given the complex signal and 
% frequency vector. Also return the complex signal fft normalized
function complex_signal_fft_normalized = plot_fft_station(complex_signal, f, radio_station)
    complex_signal_fft = fftshift(fft(complex_signal));
    complex_signal_fft_normalized = abs(complex_signal_fft) / max(abs(complex_signal_fft));
    
    figure(2);
    plot(f/1e3, mag2db(abs(complex_signal_fft_normalized)));
    xlabel('Frequency (kHz)');
    xlim([-600, 600])
    ylim([-60, 3])
    ylabel('Magnitude (dBFS)');
    title(['Frequency Domain Signal for Station ' radio_station]);
end 