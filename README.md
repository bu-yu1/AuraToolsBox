markdown
# AuraToolsBox · 桌面工具箱
Windows 轻量工具启动器，分组管理本地软件，附带桌面悬浮小窗快速切换板块。
**纯 PowerShell + WinForms 实现，无需安装第三方依赖。**

![主界面截图](docs/main.png)
![悬浮小窗截图](docs/widget.png)

## ✨ 功能特性
- 主界面：左侧板块分组，右侧图标墙；自动从exe提取程序图标
- 可视化添加工具：选择exe/快捷方式，填写名称，配置自动保存
- 自定义板块分类；右键图标移除条目（**不会删除原程序文件**）
- 桌面浮窗：半透明玻璃圆角、可拖动；滚轮/方向键切换板块；60秒自动翻页
- 配置文件 `config.json`，支持手动编辑修改

## 🖥️ 运行环境
- Windows 10 / Windows 11
- 系统自带 **PowerShell 5.1**，不需要额外下载安装

## 🚀 快速上手
1. 下载仓库源码，把整个 `src` 文件夹解压到任意目录（例：`D:\Tools\AuraToolsBox`）
2. 双击 `启动工具箱.vbs` → 打开主管理界面
3. 双击 `启动浮窗.vbs` → 打开桌面悬浮小窗口
> 首次打开列表为空，点板块末尾「**＋ 添加工具**」来导入本地程序。

## ⚙️ 可选配置
### 开机自启浮窗
1. Win+R，输入 `shell:startup` 打开开机启动文件夹
2. 将 `启动浮窗.vbs` 创建快捷方式，拖入此文件夹

### config.json 配置格式
```json
{
  "title": "我的工具箱",
  "groups": [
    {
      "name": "AI工具",
      "items": [
        { "name": "示例软件", "path": "D:\\apps\\demo.exe", "args": "-参数" }
      ]
    }
  ]
}
args 程序启动参数，可省略
路径失效的程序会标记 (未安装)，不影响其余功能
🎮 浮窗操作说明
表格
操作	说明
按住标题栏拖动	移动浮窗，位置自动记忆
鼠标滚轮 / 方向键 / PageUp/PageDown	切换板块
自动翻页	60 秒自动切换下一组
Esc / 右键菜单	关闭悬浮窗
📂 项目目录
plaintext
src/
  ToolBox.ps1        # 主界面脚本
  Widget.ps1         # 桌面浮窗脚本
  config.json        # 用户配置文件
  启动工具箱.vbs      # 主界面启动器
  启动浮窗.vbs        # 悬浮窗启动器
docs/
  main.png           # 主界面截图
  widget.png         # 浮窗截图
❓ 常见问题
双击 vbs 没有反应
右键 vbs 文件 → 打开方式 → 选择 wscript.exe
Windows Defender / 安全软件拦截，将整个文件夹加入白名单
图标显示异常
图标直接从目标 exe 提取；无法获取时显示默认图标；.lnk快捷方式会自动解析真实 exe 路径。
修改 config.json 不生效
关闭全部工具箱窗口，重新运行 vbs，配置才会加载。
⚠️ 下载解压后如果 PowerShell 阻止脚本运行：
右键 src 文件夹 → 属性 → 勾选「解除锁定」，或者 PowerShell 执行：
powershell
Unblock‑File .\src\*.ps1
License
MIT
plaintext

## 🚫 `.gitignore`（Windows PowerShell项目专用，放到仓库根目录）
> 不要把用户本地生成的config.json、缩略图、系统垃圾提交到github
```gitignore
# Windows系统垃圾
Thumbs.db
Desktop.ini
$RECYCLE.BIN/

# 用户本地配置（不提交个人配置，仓库放模板即可）
src/config.json

# PowerShell临时
*.log
*.tmp

# 图片编辑缓存
*.psd
*.ai
提示：你仓库 src 里面保留一份空白模板 config.json；用户本地自己生成自己的配置，不会上传。
📁 你的本地文件夹结构（上传 GitHub 之前整理好）
plaintext
AuraToolsBox/
├─ src/
│   ├─ ToolBox.ps1
│   ├─ Widget.ps1
│   ├─ config.json    # 空白模板，不要放你自己的私人配置
│   ├─ 启动工具箱.vbs
│   └─ 启动浮窗.vbs
├─ docs/
│   ├─ main.png
│   └─ widget.png
├─ README.md
└─ .gitignore
✅ 上传 GitHub 操作（Windows 本机 git，不要放到 Linuxpwn 环境！）
这个是 Windows 工具，在你的 Windows 电脑操作 git，不要放到刚才 Ubuntu pwn 环境！
github 网页新建仓库：名字 AuraToolsBox，Public，Add license 选 MIT，关闭 Initialize README
Windows 终端（git bash /powershell）进入上面这个根目录 AuraToolsBox
bash
运行
git init
git add .
git commit -m "初始提交：AuraToolsBox桌面工具箱"
git branch -M main
git remote add origin https://github.com/你的ID/AuraToolsBox.git
# 因为网页端创建带MIT LICENSE，会出现无关历史，先拉取合并
git pull origin main --allow-unrelated-histories
git push -u origin main
