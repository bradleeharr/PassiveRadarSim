# PassiveRadarSim
Project for Radar Signal Processing - Passive Radar Simulation from RTL-SDR FM Data
# Description
The purpose of this project is to explore the steps of passive radar signal processing. A passive radar, as 
described by [1], is a radar that relies on a transmitter external to its own system. This kind of radar can 
be called passive bistatic radar, passive covert radar, or passive coherent location.
Passive radar can have several applications. Some uses for short range passive radar include detecting 
vehicles or smuggler drones in border areas detecting flying objects in the vicinity of small airports [2] 

# FM Radio: Waveform Analysis
FM Radio is the transmitter I chose to cover due to the strong signal power used in the 
transmitters and the continuous operation of several stations making it very available and accessible.
In broadcast FM passive radar, typically fast pop or rock radio stations are used due to the higher 
bandwidths and more stable signal content [1]. To test some of this, I collected FM Radio data using an 
RTL-SDR from a single antenna from three different stations at 100.5 MHz, 102.7 MHz, and 104.1 MHz.
100.5 MHz is a rock radio station and 102.7 MHz and 104.1 MHz are pop radio stations.
The data was collected using GNU Radio with an RTL-SDR block and file sink that stored the data as 
characters with real and imaginary components interleaved. The setup and results can be seen in Figure 
1 and 2

<h3> Figure 1: Flowgraph collecting data from 104.1 MHz channel </h3>

![image](https://github.com/bradleeharr/PassiveRadarSim/assets/56418392/31bb5cf2-b75d-4f61-bc6c-5d8c7ca303f9)

<h3> Figure 2: Histogram and frequency content of samples collected for 104.1 MHz channel </h3>

![image](https://github.com/bradleeharr/PassiveRadarSim/assets/56418392/8030bb78-7ad2-403b-866f-ea96883d49d9)

I used a sample rate of 2.4 MS/s, which included frequency content from other channels. To reduce interference from other channels, I passed the data through a Hamming window low-pass filter with an order of 30 and cutoff frequency 480 kHz. To compare the signals, the frequency and autocorrelation response for one second of data, can be seen in Figure 3.

<h3> Figure 3: Frequency Response and Autocorrelation Response for 2 seconds of data from stations at 100.4 MHz, 102.7 MHz, and 104.1 MHz </h3>

![image](https://github.com/bradleeharr/PassiveRadarSim/assets/56418392/9ac72b26-2ba6-4918-a1a2-c8f48b59e4fa)

The frequency response of the three signals are similar, as they are all high-quality FM broadcasts. In comparison to the others, the 102.7 MHz channel has the narrowest bandwidth, and has worse sidelobes in the autocorrelation response than the other channels, so it is likely not ideal for a radar waveform. The 104.1 MHz channel has decent bandwidth and the sidelobes in the autocorrelation response at ±20μs lag are -30 dB, which is significantly good performance. The 100.5 MHz channel has even better peak-to-sidelobe response of -31.5 dB at ±17.5μs lag.

It is important to note that these measurements only correspond to a single instant of time, and due to the nature of the broadcasts’ constantly changing signal content, this does not fully represent the capability of the overall broadcast.
For a second metric of the waveforms’ performance, a good measure may be the bandwidth over time, so I calculated the 3dB bandwidth every 0.1s for the three signals over 30 seconds of time.  The bandwidth over time changed significantly with the signal, but over the interval that was sampled, the 104.1 MHz channel has the best bandwidth on average.

<h3> Figure 4: Bandwidth over time measurements </h3>

![image](https://github.com/bradleeharr/PassiveRadarSim/assets/56418392/751ef72f-f073-4e14-ad2f-303194b47a41)

# Cross Ambiguity Function
Typically in a passive radar system, waveforms will be received at two or more antennas, with one signal being used for reference and another for surveillance. Using both reference and surveillance signals, a cross-ambiguity function (CAF) can be calculated to create a range-velocity map where detection algorithms can be used to detect targets.
The formula for the CAF is [1]:

![image](https://github.com/bradleeharr/PassiveRadarSim/assets/56418392/e8967046-af18-433c-bd8e-f85b99f37584)

Where x_e (n) is the echo signal received from a surveillance source, x_r (n) is the reference signal, n is the index of each time delay, and k is the index of each frequency bin. 
To begin the analysis, I computed the CAF between two identical band-limited Gaussian noise sources, as shown in Figure 5. Given that the waveforms are identical and no frequency or doppler shift is present, the CAF contains a single peak at 0 delay and 0 frequency shift. This represents the point where the waveforms align, and the function reduces to what is called a self-ambiguity function. 

<h3> Figure 5: (a) Noise Signal (b) 0-Range Cut of Ambiguity Function (c) 0-Velocity Cut of Ambiguity Function (d) Top View of Ambiguity Function </h3>

![image](https://github.com/bradleeharr/PassiveRadarSim/assets/56418392/d4966e97-6d3c-4a86-9a7f-ec97d5d7fd9a)

I then calculated the self-ambiguity functions of the three waveforms for the first coherent processing interval (CPI). This can be seen in Figure 6. The differences caused by sidelobe and noise fluctuations show that the 102.7 MHz channel signal clearly has worse performance compared to the others, with sidelobes and noise fluctuations that spread throughout the entire spectrum. Again, the 100.5 MHz channel has the best performance in this interval.

<h3> Figure 6: Self Ambiguity Functions for first CPI of 100.5, 102.7, and 104.1 MHz channels  </h3>

![image](https://github.com/bradleeharr/PassiveRadarSim/assets/56418392/d4a1750d-1f5b-4322-92f8-16ad05427cf3)

Following the self-ambiguity analysis, I used a simple model to create a second signal, x_e from the reference signal x_r, adding an echo component with a doppler shift, f_d, and delay, d, to simulate a theoretical reflected echo signal being produced by the target with some attenuation, α.

![image](https://github.com/bradleeharr/PassiveRadarSim/assets/56418392/6711b73e-913a-42cc-b0a8-00b9096ef771)

For the first CPI of the three waveforms, I calculated the CAF of the two signals x_e and x_r, for α = 0.5 and α = 0.05, which correspond to a 6 dB and 26 dB decrease in target signal power. For the doppler shift and delay I set f_d = -50, and d=30 samples, which corresponds to a bistatic range of 30km and bistatic velocity of ~150 m/s at the sample frequency 480kHz and carrier frequencies 100–104MHz. The results can be seen in Figure 7. The peaks around 0 velocity and 0 range show the direct-path signal being included. In all three functions for α = 0.5, the targets are visually detectable at the correct range and velocity. However, in the more challenging scenario with α = 0.05, the target is less clear. The direct path interference includes high power sidelobes that make the target detection more difficult and would potentially cause more false alarms.

<h3> Figure 7: Cross Ambiguity Functions between simulated x_e and x_r for first CPI for of 100.5, 102.7, and 104.1 MHz channels </h3>

![image](https://github.com/bradleeharr/PassiveRadarSim/assets/56418392/141b98ae-4d46-4640-981b-d1add5d8dd53)

# Clutter Removal 

As we see in the previous ambiguity function example, direct path interference and clutter can make it more difficult to detect objects. As a result, conventional passive radar systems use clutter removal algorithms to filter interference from the reference signal.

I used clutter removal between the simulated x_e and x_r signals in the range response, with the objective of removing positive-delay reflections of the reference signal. The results can be seen in Figure 8. This time, I have restricted the color limits to focus on the detections itself. The limit ranges from 85 dB to 100 dB. In all three scenarios, applying clutter filtering has greatly cleared up the CAF. After the clutter filtering has been applied, the map shows only the target and residual interference in all three scenarios.

<h3> Figure 8.  Cross Ambiguity Functions between simulated x_e and x_r before and after clutter removal for first CPI for of 100.5, 102.7, and 104.1 MHz channels. Color limits range from 85 to 100 dB </h3>

![image](https://github.com/bradleeharr/PassiveRadarSim/assets/56418392/98d4807f-1f9d-43ab-956e-7f4aba07a314)
![image](https://github.com/bradleeharr/PassiveRadarSim/assets/56418392/660d786b-1d0d-4fed-8df0-8ecee56d4859)


# References
[1] Mateusz Malanowski, Signal Processing for Passive Bistatic Radar, Artech, 2019.
[2] K. Abratkiewicz, A. Księżyk, M. Płotka, P. Samczyński, J. Wszołek and T. P. Zieliński, "SSB-Based 
Signal Processing for Passive Radar Using a 5G Network," in IEEE Journal of Selected Topics in Applied 
Earth Observations and Remote Sensing, vol. 16, pp. 3469-3484, 2023
