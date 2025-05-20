# 5G
https://www.mathworks.com/help/5g/ug/nr-prs-positioning.html



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



## UE.m
用來模擬使用者裝置（User Equipment, UE）接收訊號的模組。主要功能是模擬 UE 接收多個基站（gNB）訊號並加入雜訊，以真實反映 5G 無線傳輸環境。
1. 屬性（Properties）：
   - ID：裝置編號
   - Position：UE 所在的空間座標（x, y）
   - NumRx：接收天線數量（預設為 1 根）

2. 方法（Methods）：
   - UE(id, pos, numRx)：建構子，用來初始化 UE 的位置與天線數量。
   - receive(gnbList, fs, snr_dB)：主功能函數，模擬 UE 接收來自多個 gNB 的訊號。


接收模擬流程：
1. 屬性（Properties）：
   算出每個基地台到 UE 的距離，根據距離和頻率，利用 Friis 模型估計訊號會被削弱多少（路徑損耗）。同時也會算出訊號傳過來會延遲多久，這些延遲會反映在波形中。

2. 模擬真實通訊環境（使用 TDL-C 通道模型）
   用 3GPP 推出的 TDL-C 模型，模擬真實世界傳輸環境下訊號會被建築物、牆壁等物體反射或擋住，形成多條路徑（多徑效應）
   
3. 把所有基地台的波形組合起來
   UE 把每個基地台傳來的波形記錄下來，根據天線數量儲存在一個三維矩陣 rxMat 裡。把所有訊號加總起來，形成一個總接收訊號 rxSum，可以拿來做定位或分析

4. 加入雜訊模擬干擾
   根據 SNR 設定來加入對應強度的高斯雜訊。
