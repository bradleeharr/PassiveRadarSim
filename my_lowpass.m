% Applies a hamming window low pass filter to signsl for order and cutoff frequnecy
function filtered_signal = my_lowpass(signal, order, normalized_cutoff_freq)
    % Create the Hamming window
    N = order - 1;
    n = 0:N;
    fc = normalized_cutoff_freq;
    sinc_func = sin(pi * fc * (n - N/2)) ./ (n - N/2); % Sinc function
    sinc_func(n == N/2) = 2 * pi * fc; % Handle 0/0. 
    hamming_window = 0.54 - 0.46 * cos(2 * pi * n / N);

    % Compute the filter coefficients
    filter_coeffs = sinc_func .* hamming_window;
    % Normalize and run the filter 
    filter_coeffs = filter_coeffs / sum(filter_coeffs);
    filtered_signal = conv(signal, filter_coeffs, 'same');
    %figure(9); subplot(2,1,1); plot(filtered_signal); subplot(2,1,2); plot(signal); 
end