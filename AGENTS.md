# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## 專案概述

這是一個使用 **Godot 4.6** 開發的遊戲專案，目前處於初始階段（無場景、無腳本）。

- **引擎**：Godot 4.6
- **語言**：GDScript（`.gd` 檔案）
- **物理引擎**：Jolt Physics
- **渲染模式**：GL Compatibility（相容性渲染器），Windows 備援 D3D12

## 常用指令

```bash
# 開啟 Godot 編輯器並載入專案
godot --path "E:\新遊戲專案"

# 直接執行遊戲（無頭模式，適合測試）
godot --headless --path "E:\新遊戲專案"

# 執行特定場景
godot "res://scenes/main.tscn"

# 匯出專案（需先在編輯器設定匯出範本）
godot --export-release "Windows Desktop" "E:\build\game.exe"
```

## 專案結構慣例

建議依下列結構組織專案：

```
新遊戲專案/
├── scenes/          # .tscn 場景檔
├── scripts/         # .gd GDScript 腳本
├── assets/
│   ├── textures/    # 圖片資源
│   ├── audio/       # 音效、音樂
│   └── fonts/       # 字型
├── resources/       # .tres 自訂資源
└── addons/          # 第三方插件
```

## 架構說明

- **場景（Scene）**：Godot 的基本組合單元，每個場景是一棵節點樹，儲存為 `.tscn`
- **腳本（Script）**：`.gd` 腳本附加到節點，繼承該節點的類型（如 `extends Node2D`）
- **資源（Resource）**：`.tres` 可重複使用的資料物件（例如設定、統計數值）
- **Autoload / Singleton**：全域可存取的腳本，在 Project Settings > Autoload 中設定

## Godot 4 開發注意事項

- 訊號連接使用新語法：`node.signal_name.connect(callable)`
- 等待訊號：`await node.signal_name`
- `@export` 變數可在編輯器 Inspector 中直接編輯
- 使用 `@onready var node = $NodePath` 取得節點引用
- 場景資源路徑以 `res://` 開頭，使用者資料路徑以 `user://` 開頭
