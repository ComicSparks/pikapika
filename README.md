PIKAPIKA - 漫画客户端
========
[![license](https://img.shields.io/github/license/niuhuan/pikapika)](https://raw.githubusercontent.com/niuhuan/pikapika/master/LICENSE)
[![releases](https://img.shields.io/github/v/release/niuhuan/pikapika)](https://github.com/niuhuan/pikapika/releases)
[![downloads](https://img.shields.io/github/downloads/niuhuan/pikapika/total)](https://github.com/niuhuan/pikapika/releases)

- 美观易用且无广告的漫画客户端, 能运行在Windows/MacOS/Linux/Android/IOS中。
- 本仓库仅作为学习交流使用, 请您遵守当地法律法规以及开源协议。
- 您的star和issue是对开发者的莫大鼓励, 可以源仓库下载最新的源码/安装包, 表示支持/提出建议。
- 源仓库地址 [https://github.com/niuhuan/pikapika](https://github.com/niuhuan/pikapika)

## 界面 / 功能

![阅读器](images/reader.png)

### 分流

VPN->代理->分流, 这三个功能如果同时设置, 您会在您手机的VPN上访问代理, 使用代理请求分流服务器。

### 漫画分类/搜索

![分类](images/categories_screen.png) ![列表](images/comic_list.png)

### 漫画阅读/下载/导入/导出

您可以在除IOS外导出任意已经完成的下载到zip, 从另外一台设备导入。 导出的zip解压后可以直接使用其中的HTML进行阅读

![导出下载](images/exporting.png)

![HTML预览](images/exporting2.png)

### 游戏

![games](images/games.png)
![game](images/game.png)

## 特性

- [x] 用户
    - [x] 登录 / 注册 / 获取个人信息 / 自动打卡
- [x] 漫画
    - [x] 分类 / 搜索 / 随机本子 / 看此本子的也在看 / 排行榜
    - [x] 在分类中搜索 / 按 "分类 / 标签 / 创建人 / 汉化组" 检索
    - [x] 漫画详情 / 章节 / 看图 / 将图片保存到相册
    - [x] 收藏 / 喜欢
    - [x] 获取评论 / 评论 / 评论回复 (社区评论后无法删除, 请谨慎使用)
- [x] 游戏
    - [x] 列表 / 详情 / 无广告下载
- [x] 下载
    - [x] 导入导出 / 无线共享 / 移动设备与PC设备传输
- [ ] 聊天室
- [x] 缓存 / 清理
- [x] 设备支持
    - [x] 安卓
        - [x] 高刷新频率屏幕适配 (90/120/144... Hz)
        - [x] 安卓10以上随系统进入深色/夜间模式

## 其他说明

- 在ios/android环境 数据文件将会保存在程序自身数据目录中, 删除就会清理
- 在 windows 数据文件将会保存在程序同一目录
- 在 macos 数据文件将会"~/Library/Application Support/pikapika"
- 在 linux 数据文件将会"~/.pikapika"

## 运行 / 构建

这个应用程序使用golang和dart(flutter)作为主要语言, 可以兼容Windows, linux, MacOS, Android, IOS

使用了不同的框架桥接到桌面和移动平台上

- go-flutter => Windows / MacOS / Linux
- gomobile => Android / IOS

![平台](images/platforms.png)

### 开发环境准备

- [golang](https://golang.org/) (1.16以上版本)
- [flutter](https://flutter.dev/) (stable-2.8.0)(flutter不同版本api差异较大,建议使用临近的版本)

### 环境配置

- 将~/go/bin ($GoPath/bin) 设置到PATH环境变量内
- golang开启模块化
- 设置GoProxy (可选,在中国大陆网络建议设置)
- 参考地址 [https://goproxy.cn/](https://goproxy.cn/)

### 桌面平台 (go-flutter)

- [安装hover(go-flutter编译脚手架)](https://github.com/go-flutter-desktop/hover)
  ```shell
  GO111MODULE=on go get -u -a github.com/go-flutter-desktop/hover
  # 或
  go install github.com/go-flutter-desktop/hover@latest
  ```
- 安装gcc
  ```shell
  # Windows需要安装MSYS(mingw-w64-x86_64-gcc), 并将gcc路径设置到PATH环境变量内
  # MacOS需要安装XCode
  # Linux使用命令行安装gcc
  ```
- 执行编译命令 ($system替换为windows/darwin等)
  ```shell
  hover run
  hover build $system
  ```

### Linux的附加说明

- linux编译可能会遇到的问题
  ```shell
  # No package 'gl' found
  sudo apt install libgl1-mesa-dev
  # X11/Xlib.h: No such file or directory
  # 或者更多x11的头找不到等
  sudo apt install xorg-dev
  ```
- 字体不显示
    ```shell
    # 将字体文件复制到项目目录下
    mkdir -p fonts
    cp -f /usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf fonts/
    ```
    ```yaml
   # 编辑 pubspec.yaml
     fonts:
       - family: Roboto
         fonts:
           - asset: fonts/DroidSansFallbackFull.ttf
    ```

### 移动端 (gomobile)

- 编译环境
  ```shell
  # 安卓环境需要安装AndroidSDK, 并且安装platforms以及ndk, 配置 ANDROID_HOME
  # IOS需要安装xcode以及CocoaPods 
  gem install cocoapods
  ```
- [安装gomobile](https://github.com/golang/mobile)
  ```shell
  go install golang.org/x/mobile/cmd/gomobile@latest
  ```
- 执行编译命令 (bind-android.sh/bind-ios.sh根据平台选择, $system替换为apk/ipa等)
  ```shell
  cd go/mobile
  go get golang.org/x/mobile/cmd/gobind
  sh bind-ios.sh
  sh bind-android.sh
  cd ../../
  flutter build $system
  ```

## 请您遵守使用规则

本软件或本软件的拓展, 个人或企业不可用于商业用途, 不可上架任何商店

拓展包括但是不限于以下内容

- 使用本软件进行继续开发形成的软件。
- 引入本软件部分内容为依赖/参考本软件/使用本软件内代码的同时, 包含本软件内一致内容或功能的软件。
- 直接对本软件进行打包发布
