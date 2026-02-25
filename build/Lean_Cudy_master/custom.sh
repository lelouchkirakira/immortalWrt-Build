#!/bin/bash

# 更新並安裝 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 建立一個空的 .config 文件，等待我們用 SSH 進入配置
cd $WORKPATH
touch ./.config

# 返回目錄
cd $HOME
