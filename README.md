# 5G

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


![image](https://github.com/user-attachments/assets/4a51caf2-86cb-47e7-b9e8-84fb02650065)
