# 5G
https://www.mathworks.com/help/5g/ug/nr-prs-positioning.html

## Version 2

This project simulates 5G network scenarios to implement Positioning Reference Signal (PRS) and evaluate which frequency band is most suitable for PRS-based positioning.
The frequency selection is based on currently deployed 5G bands in Taiwan, including Band N78 (3.3–3.8 GHz) and Band N79 (4.4–5.0 GHz), and also references international allocations such as EU (Band N78), USA (C-band, 3.7–3.98 GHz), and Japan (around 4.5 GHz).
Through simulation and analysis, this project aims to provide insights into the optimal frequency bands for 5G PRS deployment.

## Simulation-Outside
![image](https://github.com/user-attachments/assets/e24da469-6023-40af-8aa3-bb8a58ab75b2)


## Simulation-Single Wall
![image](https://github.com/user-attachments/assets/6a6a9069-ed37-40e8-a8c3-c0be13e0e4ba)


## Simulation-House
![image](https://github.com/user-attachments/assets/220412e6-212e-4c88-8b8c-94d9aebfe706)



## Version 2

## estimatePosition.m

Purpose:
This function estimates the 2D position `[x, y]` of a User Equipment (UE) based on Time Difference of Arrival (TDOA) measurements relative to a reference gNB (gNB1).  
The goal is to minimize the total error between observed TDOA values and the predicted TDOA values calculated from the estimated UE position.


Function Workflow：

Step 1：Initial Guess
init = mean(gnb);
→ Uses the geometric center (average position) of all gNBs as the initial guess for the UE position.

Step 2：Cost Function Definition
loss_fn = @(p) ...
    ( ((norm(p - gnb(2,:)) - norm(p - ref_pos))/c - tdoa(2))^2 + ...
      ((norm(p - gnb(3,:)) - norm(p - ref_pos))/c - tdoa(3))^2 );
→ Defines an objective (loss) function that sums the squared differences between:
Predicted TDOA (based on distance differences from the estimated UE position to each gNB, divided by speed of light), and Measured TDOA values.

Step 3：Nonlinear Optimization
[pos, ~] = fminsearch(loss_fn, init, options);
→ Uses fminsearch (Nelder-Mead simplex algorithm) to minimize the loss function and return the estimated UE position that best fits the observed TDOA data.


## isPathBlocked.m

Purpose：
Determines how many walls block the straight-line path between two positions `p1` and `p2`.  
It returns the total number of intersections (how many walls the path crosses).

Parameters：
- p1 → Start point of the path [x1, y1].
- p2 → End point of the path [x2, y2].
- walls → Cell array of wall segments.
Each wall is represented as [x1 y1 x2 y2].

Process：

Step 1: Initialize count = 0.

Step 2: Loop through each wall in walls.

Step 3: For each wall (represented by endpoints [x1 y1 x2 y2]), use segmentsIntersect() to check whether it intersects with the path segment p1 → p2.

Step 4: If an intersection is detected, increment count.

Step 5: After all walls are checked, return count.



## prs_gui.m
This GUI serves as the main launcher and coordinator for a **5G PRS + TDOA simulation system**.  
It initializes the simulation scene, sets up gNB positions, defines wall obstacles, runs TDOA-based positioning, and visualizes the results in real time.


Key Workflow：

1. Initialization
   **Parameter Setup**:Configure initial parameters:
  - Number of simulation steps
  - UE movement radius
  - Wall thickness
  - Scene type: `Outside`, `Single wall`, or `House`

   **Launch GUI**:  
   Create the main interface using MATLAB `uifigure`.
   
   **Scene Setup**:  
   Place gNBs (base stations) at predefined locations (equilateral triangle), Draw walls according to the selected scene using `drawScene()`.


2. TDOA Positioning Pipeline (simulateTDOA)
   
        (1)**UE Signal Reception Simulation**  
             Simulate UE location within a given radius and assume ideal signal reception (no explicit waveform processing).

        (2)**TDOA Calculation**  
             Compute time differences between the distances to different gNBs, assuming constant speed of light.

        (3)**Position Estimation**  
             Estimate UE position by solving a nonlinear least squares (NLS) optimization problem using `estimatePosition()` based on TDOA measurements.

        (4)**Real-time Visualization**  
             Continuously update the GUI:
                - Display estimated UE position
                - Draw gNB locations
                - Show wall obstacles
                - Update simulation status text


## simulateTDOA.m
This function implements the core **5G PRS + TDOA positioning simulation loop**.  
It simulates a UE moving along a circular trajectory, calculates noisy TDOA measurements at each step, accounts for wall-induced delays, and estimates the UE position using nonlinear optimization.  
Results are plotted in real time on the GUI axes.
 

Workflow：

Step 1：Input Parameters
        - ax：Axes object for visualization
        - gnb：gNB positions (3 x 2 matrix)
        - steps：Number of simulation steps (UE path points)
        - radius：Radius of UE trajectory (meters)
        - thick_cm：Wall thickness (centimeters)
        - scene： Scene type: 'Outside', 'Single wall', 'House'
        - infoText：Text area for showing simulation progress
        - walls：Cell array of wall segments used for blocking/delay


Step 2：UE Trajectory
UE moves in a circular path of given radius.

Step 3：Frequency Setup
Simulation runs for 5 frequencies:700 MHz, 1.8 GHz, 2.6 GHz, 3.5 GHz, 28 GHz
Each frequency uses a different plot color.

Step 4：Main Simulation Loop (Per Step)
For each UE position:
     (1)True TDOA Calculation
        - Compute true distances from UE to each gNB.
        - Convert to TOA → compute TDOA relative to reference gNB.

     (2)Wall Delay Modeling
          For each gNB, check if the path crosses walls

     (3)Noise Injection
        - Add Gaussian noise to TDOA values.
        - Noise level depends on frequency.

     (4)Position Estimation
        - Call estimatePosition(gnb, tdoa) to estimate current UE position.
        - Check estimation validity (distance threshold).

     (5)Visualization
        - Plot true UE position.
        - Plot estimated positions (different color per frequency).
        - Update info text with cumulative error and lost count.


Step 5：Real-time Visualization
Axes show:
    - gNB positions (red squares)
    - True UE path (black circle)
    - Estimated positions (colored dots per frequency)
Info text displays:
    - Cumulative positioning error
    - Number of failed (lost) estimations




## drawScene.m
`drawScene(ax, scene, thick)`  
Draws walls in the specified axes `ax` according to the selected `scene`.

Parameters：
- ax：Axes handle where the scene will be drawn.
- scene：Name of the scene to draw.
  Currently supported 'Single wall' : A single vertical wall. 'House' : Four walls forming a rectangular house.
- thick：Line thickness parameter. The actual line width will be thick / 10.

Return Value：
- walls ➜ A cell array containing wall coordinates.
Each wall is defined as [x1 y1 x2 y2].


## PRS_TDOA_SIMULATOR_MAIN.m
This script serves as the **main entry point** to launch the 5G PRS + TDOA Simulator.  
It sets up the environment and starts the GUI application.

Workflow：
Step 1: Add Module Paths
Step 2: Launch GUI
Starts the interactive GUI (prs_gui.m):
- Allows users to configure simulation parameters.
- Visualizes positioning results in real time.
- Provides interactive control (Start / Stop / Reset).

## Version 1

5G PRS + GNS3 定位系統 

專案目標：把 MATLAB 的 5G PRS 定位演算法，透過位置引擎 REST 服務，整合進 GNS3 所建的 5G 網路拓樸，展示「近真實」的 TOA/TDOA 定位流程。
在 GNS3 搭建的小型 5G 網路（3 gNB + Open5GS Core）上，
透過 MATLAB 產生並分析 PRS 量測，將 TDOA 量測資料送至「位置引擎伺服器」(Flask)，
回傳 UE 座標並在 MATLAB GUI 即時顯示——打造「近真實」的 5G 定位全流程示範。


┌─────────┐  UDP/TCP   ┌──────────────────┐
│ MATLAB  │──────────▶│  位置引擎容器      │
│ PRS 模擬│            │  (Python/Node)    │
└─────────┘            └────────┬─────────┘
                               │REST / gRPC
                               ▼
          ┌──────────────────────────────┐
          │ GNS3 拓撲 (Docker/VM/IOU)    │
          │ ┌─────┐  ┌─────┐  ┌───────┐ │
          │ │gNB0 │..│gNB1 │..│gNB2   │ │
          │ └─────┘  └─────┘  └───────┘ │
          │     │        │        │      │
          │    N2/N3   N2/N3   N2/N3    │
          │          (Open5GS CN)       │
          └──────────────────────────────┘

MATLAB UE 模擬器 ue_control_ui.m





  TOA → TDOA 模式已可隨 UE 位置即時定位。

  支援 15/30/60 kHz 三頻段、SNR/MIMO 調整。

TDOA 解算器 locateByTDOA.m

待完成
MATLAB refresh_rx → Flask POST  :Cindy
Flask /solve → 回傳 pos

補上 locateByTDOA Numpy 版 + Error handling Paul

誤差統計報告 SNR Sweep、多徑模型 (TDL‑C) Kevin




Matlab part result

![image](https://github.com/user-attachments/assets/4a51caf2-86cb-47e7-b9e8-84fb02650065)


![image](https://github.com/user-attachments/assets/c7594034-ca04-452b-9d60-a10222b3172d)


![image](https://github.com/user-attachments/assets/ecd39edb-7c1b-47e1-8722-085ac739865e)



Version 1
## UE.m — Simulated User Equipment (UE) Signal Reception Module

This module simulates the behavior of a 5G user equipment (UE) receiving signals from multiple gNBs (base stations). 
It models realistic wireless transmission effects, including multipath propagation and additive noise, to emulate a real-world 5G positioning environment.

1. Properties：
   - **ID**：UE device identifier 
   - **Position**：Spatial coordinates of the UE `[x, y]`
   - **NumRx**：Number of receiving antennas (default: 1)  


2. Methods：
   - UE(id, pos, numRx)：Initializes a UE object with a given ID, position, and number of antennas.
   - receive(gnbList, fs, snr_dB)：the core function that simulates signal reception from multiple gNBs.

Signal Reception Flow：

Step 1. Distance and Delay Calculation
For each gNB, the UE calculates the distance, estimates signal attenuation using the Friis transmission model, and applies a time delay to simulate real-world signal propagation.

Step 2. Realistic Channel Modeling (TDL‑C)
Applies the 3GPP TDL‑C model to simulate multipath fading caused by reflections and obstructions, creating a realistic wireless environment.
   
Step 3. Signal Aggregation (Combine the waveforms from all the base stations)
Stores each gNB’s received waveform in a 3D matrix rxMat, and sums them into rxSum for positioning or further analysis.

Step 4. Additive Noise
Gaussian noise is added based on the specified SNR (signal-to-noise ratio) to simulate interference.


## detectTOA.m
This module estimates the **Time of Arrival (TOA)** of signals received from multiple gNBs (base stations). 
It uses **cross-correlation** combined with **parabolic interpolation** to accurately determine when each signal reaches the UE (User Equipment), even in the presence of noise and multipath effects.

Core Concept:
The UE compares the received waveform (`rx`) with each gNB's known transmitted waveform. 
The point of **maximum similarity** (highest cross-correlation) indicates when the signal most likely arrived.  

However, since sampling occurs in discrete time steps, the true arrival time may lie **between samples**. 
Therefore, a **parabolic interpolation** is applied around the correlation peak to refine the TOA estimate with sub-sample precision, significantly improving overall positioning accuracy.


Processing Flow：

1.**Input**
   - `rx`: Received waveform at the UE (may contain signals from multiple gNBs plus noise)
   - `gnbList`: Array of gNB objects with known transmitted signals
   - `fs`: Sampling frequency (Hz), used to convert samples into seconds

2.**Per gNB Processing**
   - Extract reference waveform from each gNB
   - Perform **cross-correlation** between `rx` and the reference waveform
   - Locate the **index of the correlation peak**, indicating the best time match
  
3. **Parabolic Interpolation**
Apply parabolic interpolation around the peak using three points to estimate a more precise offset delta, refining TOA to sub-sample accuracy.


4. **TOA Calculation**
Compute TOA by subtracting the reference waveform length from the peak index pk, adding the interpolation offset delta, and dividing by the sampling rate fs to convert to seconds.


## gNodeB.m
This module defines a gNodeB class that simulates a 5G base station (gNB) transmitting Positioning Reference Signals (PRS) for UE localization.


## locateByTDOA.m
This function performs **2D localization** of a User Equipment (UE) using the **Time Difference of Arrival (TDOA)** technique. 
It requires at least **three gNBs (base stations)** and does **not rely on clock synchronization** between the UE and gNBs.
The function applies **Nonlinear Least Squares (NLS)** optimization with the following objective:![image](https://github.com/user-attachments/assets/caea8881-50e4-4b63-863f-fffa99102cef)



## locateByTOA.m_ TOA-Based UE Position Estimation
This function estimates the UE's position using **Time of Arrival (TOA)** measurements from multiple base stations (gNBs). 
It finds the point in space that minimizes the total error between: the **estimated distances** (from UE to each gNB) and the **measured distances** (derived from TOA × speed of light)


Process Overview:

1. **Initial Guess**  
   The algorithm starts by using the **average of all gNB positions** as the initial location estimate for the UE.
   
2. **Cost Function Construction** _ Builds a **sum of squared residuals** function that compares:
   - Estimated distance from UE to each gNB  
   - Measured distance from TOA × speed of light

3. **Optimization**  
   Uses `fminsearch` to minimize the residual function and find the best-fitting position.

4.**Return Estimated Position**  
   Outputs the estimated 2D coordinate `[x, y]` of the UE.
   

## receiver_tools.m
Defines the `detectTOA` function, which estimates the **Time of Arrival (TOA)** from each base station (`gNodeB`) to the User Equipment (UE) using the received signal. 
This function simulates how a real receiver would detect signal arrival times under noise and multipath conditions.

Processing Steps:
1. **Inputs**
   - `rx`: The complex received signal at the UE.
   - `gnbList`: A list of `gNodeB` objects (each with known transmitted PRS).
   - `fs`: Sampling frequency (Hz), used to convert sample indices to time.

2.**Per gNodeB Estimation**
   - For each gNB, call the `transmit()` method to obtain the reference PRS waveform.
   - Perform **cross-correlation** (`xcorr`) between the received signal and the reference waveform.
   - Locate the index of the **maximum correlation peak**, representing the most likely TOA point.
   - Adjust the peak index by subtracting the waveform length, then convert the result to seconds using the sampling frequency.
  
3.**Output**
Returns a `toa_list`, which contains the estimated TOA (in seconds) for each base station.



## scs_to_fs.m
In 5G NR systems, the **Subcarrier Spacing (SCS)** is configurable depending on application needs — commonly set to **15 kHz**, **30 kHz**, or **60 kHz**. 

Input
scs_kHz: Subcarrier spacing in kHz (typical values include 15, 30, 60)

Output
fs: Corresponding sampling frequency in Hz, assuming 4096 FFT size by default

Formula
![image](https://github.com/user-attachments/assets/4cab5013-ad98-43e9-9218-219b64030fd3)

 **Conversion Principle**
In 5G NR (New Radio), the FFT base is typically defined using **15 kHz** as the reference subcarrier spacing.  
The **sampling frequency** `fs` is calculated using the following scaling formula:![image](https://github.com/user-attachments/assets/30508762-a008-4f69-b380-2480f9dedb9e)



## ue_control_ui.m
This script builds an interactive **Graphical User Interface (GUI)** for simulating UE (User Equipment) signal reception and positioning behavior in a 5G environment.


Workflow Overview：

1.**Initialization & Main Window Setup**
   - Default UE position is set to `[100, 100]`.
   - Supports three carrier frequencies: **2.5 GHz**, **3.5 GHz**, and **4.0 GHz**.
   - Subcarrier spacing (SCS) options: **15 / 30 / 60 kHz**.
   - Sampling frequency `fs` is computed from SCS (e.g., SCS = 15 → fs = 15.36 MHz).
   - GUI window and map panel are created for interactive UE/gNB control.


2.**Control Panel Features**
   - **SNR (dB):** Adjustable signal-to-noise ratio (range: 0–30 dB).
   - **MIMO:** Select number of receiving antennas (1, 2, or 4).
   - **SCS Selection:** Toggle between subcarrier spacings.
   - **Add/Delete gNB:** Dynamically add or remove gNodeB base stations to change the simulation layout.

  
3.**UE Control & Localization Process**
   - Users can move the UE by clicking on the map or using arrow keys.
   - On every movement, the system:

     Reconstructs the UE object
     Calls `UE.receive()` to simulate reception
     Calls `detectTOA()` to estimate time of arrival (TOA)
     Computes TDOA and calls `locateByTDOA()` for position estimation
     Updates the GUI with `viewer_update()` for visual feedback

4.**Real-Time Visualization**
   - Displays actual vs estimated UE positions
   - Shows all gNB locations and connections
   - Allows multi-band and multi-parameter simulation to observe positioning accuracy under different conditions

## viewer_init.m
Initializes the graphical interface used for visualizing PRS-based signal reception and localization within the 5G UE simulation system.
Provides an interactive and informative visual panel to:
Display received PRS signals at the UE,
Show cross-correlation results from multiple gNBs,
Track UE position estimation in real time


Initialization Workflow：
1. Figure and Subplots
   - Top-left: Received signal (Real part)
   - Top-right: Cross-correlation with gNB 0
   - Bottom-left: Cross-correlation with gNB 1
   - Bottom-right: Cross-correlation with gNB 2

2. Shared Object Storage
Stores plot axes and line handles using setappdata()
Enables real-time updates from other modules (e.g., viewer_update.m)

   
4. Information Panel
   - Shows Time of Arrival (TOA) for each gN
   - Displays estimated UE coordinates from localization algorithms


## viewer_update.m
This function updates the visual interface in real time, displaying the UE’s received waveform and localization results. 
It is the **core update routine** for the GUI visualization system and is triggered whenever the UE receives new signals or changes position.

Update Components：
1. **Retrieve GUI Handles**
   Uses `getappdata()` to access the graphical axes, plot lines, and text labels stored in the global environment during `viewer_init.m`.

2. **Update Received Waveform (rx)**
   - Plots the **real part** of the complex received signal using `plot()`.
   - Refreshes the waveform display in the upper-left subplot.


3.  **Update Cross-Correlation Results (corr)**
   - For each gNB, updates the cross-correlation subplot to show correlation strength and peak timing.
   - Helps visualize signal arrival timing used for TOA/TDOA detection.

4. **Update Text Information**
   - Displays the **TOA values** (in seconds) for each gNB.
   - Displays the **estimated UE position** — either in pixel coordinates or transformed to meters depending on the system setup.



