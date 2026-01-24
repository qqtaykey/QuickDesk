# Fluent Design 组件库

QuickDesk 的 Modern Fluent Design 风格 UI 组件库。

## 组件列表

### 基础组件

| 组件 | 文件 | 说明 |
|------|------|------|
| **Theme** | Theme.qml | 主题配置（Singleton） |
| **FluentIconGlyph** | FluentIconGlyph.qml | 图标定义（Singleton） |

### 按钮与输入

| 组件 | 文件 | 说明 |
|------|------|------|
| **QDButton** | QDButton.qml | 按钮（Primary/Secondary/Danger/Success/Ghost） |
| **QDTextField** | QDTextField.qml | 文本输入框 |
| **QDCheckBox** | QDCheckBox.qml | 复选框 |
| **QDSwitch** | QDSwitch.qml | 开关 |
| **QDSlider** | QDSlider.qml | 滑块 |
| **QDComboBox** | QDComboBox.qml | 下拉选择框 |

### 容器与布局

| 组件 | 文件 | 说明 |
|------|------|------|
| **QDCard** | QDCard.qml | 卡片容器 |
| **QDDialog** | QDDialog.qml | 对话框 |
| **QDDivider** | QDDivider.qml | 分割线 |

### 反馈与提示

| 组件 | 文件 | 说明 |
|------|------|------|
| **QDToast** | QDToast.qml | 消息提示 |
| **QDProgressBar** | QDProgressBar.qml | 进度条 |
| **QDBadge** | QDBadge.qml | 徽章 |
| **QDToolTip** | QDToolTip.qml | 工具提示 |

---

## 使用方法

### 1. 导入组件

```qml
import "component"
```

### 2. 使用组件

```qml
// 按钮
QDButton {
    text: "确定"
    buttonType: QDButton.Type.Primary
    iconText: FluentIconGlyph.checkMarkGlyph
    onClicked: console.log("点击")
}

// 输入框
QDTextField {
    placeholderText: "请输入..."
    prefixIcon: FluentIconGlyph.searchGlyph
}

// 复选框
QDCheckBox {
    text: "同意协议"
    checked: true
}

// 开关
QDSwitch {
    text: "开启通知"
    checked: true
}

// 滑块
QDSlider {
    from: 0
    to: 100
    value: 50
    showValue: true
}

// 下拉框
QDComboBox {
    model: ["选项1", "选项2", "选项3"]
}

// 卡片
QDCard {
    width: 300
    height: 200
    hoverable: true
    clickable: true
    onClicked: console.log("点击卡片")
}

// 进度条
QDProgressBar {
    value: 0.5
    indeterminate: false
}

// Toast
QDToast {
    id: toast
}
// 使用: toast.show("消息", QDToast.Type.Success)

// 对话框
QDDialog {
    id: dialog
    title: "标题"
}
// 使用: dialog.show()

// 徽章
QDBadge {
    count: 5
    badgeType: QDBadge.Type.Error
}

// 分割线
QDDivider {
    Layout.fillWidth: true
}
```

---

## 组件详细 API

### QDButton

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `text` | string | "" | 按钮文本 |
| `buttonType` | enum | Primary | 按钮类型 |
| `iconText` | string | "" | 图标（使用 FluentIconGlyph） |
| `loading` | bool | false | 加载状态 |
| `enabled` | bool | true | 是否可用 |

**buttonType 枚举值：**
- `QDButton.Type.Primary` - 主要按钮（蓝色）
- `QDButton.Type.Secondary` - 次要按钮（灰色）
- `QDButton.Type.Danger` - 危险按钮（红色）
- `QDButton.Type.Success` - 成功按钮（绿色）
- `QDButton.Type.Ghost` - 幽灵按钮（透明）

### QDTextField

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `placeholderText` | string | "" | 占位文本 |
| `prefixIcon` | string | "" | 前缀图标 |
| `suffixIcon` | string | "" | 后缀图标 |
| `error` | bool | false | 错误状态 |
| `errorText` | string | "" | 错误提示文本 |

### QDCheckBox

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `text` | string | "" | 标签文本 |
| `checked` | bool | false | 选中状态 |
| `checkState` | enum | Qt.Unchecked | 三态状态 |

### QDSwitch

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `text` | string | "" | 标签文本 |
| `checked` | bool | false | 开关状态 |

### QDSlider

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `from` | real | 0.0 | 最小值 |
| `to` | real | 1.0 | 最大值 |
| `value` | real | 0.0 | 当前值 |
| `showValue` | bool | false | 拖动时显示值 |
| `decimals` | int | 0 | 小数位数 |

### QDComboBox

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `model` | var | [] | 数据模型 |
| `currentIndex` | int | 0 | 当前选中索引 |
| `displayText` | string | - | 显示文本 |

### QDCard

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `elevation` | int | 1 | 阴影级别（1-3） |
| `hoverable` | bool | false | 是否可悬停 |
| `clickable` | bool | false | 是否可点击 |

**信号：**
- `clicked()` - 点击时触发

### QDToast

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `toastType` | enum | Info | 提示类型 |
| `message` | string | "" | 消息内容 |
| `duration` | int | 3000 | 显示时长（毫秒） |
| `autoHide` | bool | true | 自动隐藏 |

**方法：**
- `show(message, type, duration)` - 显示提示
- `hide()` - 隐藏提示

**toastType 枚举值：**
- `QDToast.Type.Success` - 成功（绿色）
- `QDToast.Type.Error` - 错误（红色）
- `QDToast.Type.Warning` - 警告（橙色）
- `QDToast.Type.Info` - 信息（蓝色）

### QDDialog

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` | string | "Dialog" | 对话框标题 |
| `showing` | bool | false | 显示状态 |
| `dialogWidth` | int | 400 | 宽度 |
| `dialogHeight` | int | 300 | 高度 |
| `closeOnOverlay` | bool | true | 点击遮罩关闭 |
| `showCloseButton` | bool | true | 显示关闭按钮 |
| `footer` | list | [] | 底部按钮列表 |

**方法：**
- `show()` - 显示对话框
- `hide()` - 隐藏对话框
- `accept()` - 确认并关闭
- `reject()` - 取消并关闭

**信号：**
- `accepted()` - 确认时触发
- `rejected()` - 取消时触发
- `closed()` - 关闭时触发

### QDProgressBar

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `value` | real | 0.0 | 当前进度（0-1） |
| `indeterminate` | bool | false | 不确定模式 |
| `showValue` | bool | false | 显示百分比 |
| `progressColor` | color | primary | 进度条颜色 |

### QDBadge

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `badgeType` | enum | Primary | 徽章类型 |
| `text` | string | "" | 文本内容 |
| `count` | int | -1 | 数字（-1时显示text） |
| `maxCount` | int | 99 | 最大数字 |
| `dot` | bool | false | 圆点模式 |

**badgeType 枚举值：**
- `QDBadge.Type.Primary` - 主色
- `QDBadge.Type.Success` - 成功
- `QDBadge.Type.Warning` - 警告
- `QDBadge.Type.Error` - 错误
- `QDBadge.Type.Info` - 信息

### QDDivider

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `vertical` | bool | false | 垂直方向 |
| `label` | string | "" | 中间标签文本 |

### QDToolTip

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `text` | string | "" | 提示文本 |
| `tipDelay` | int | 500 | 延迟显示（毫秒） |

---

## 主题配置

所有颜色和尺寸在 `Theme.qml` 中定义：

### 颜色

```qml
Theme.background      // #1E1E1E - 背景色
Theme.surface         // #252525 - 表面色
Theme.primary         // #0078D4 - 主色（蓝色）
Theme.accent          // #60A5FA - 强调色
Theme.text            // #FFFFFF - 主文本
Theme.textSecondary   // #B4B4B4 - 次要文本
Theme.success         // #10B981 - 成功色
Theme.error           // #EF4444 - 错误色
Theme.warning         // #F59E0B - 警告色
Theme.info            // #3B82F6 - 信息色
```

### 尺寸

```qml
Theme.radiusSmall     // 4px
Theme.radiusMedium    // 8px
Theme.radiusLarge     // 12px
Theme.spacingSmall    // 8px
Theme.spacingMedium   // 12px
Theme.spacingLarge    // 16px
Theme.spacingXLarge   // 24px
Theme.spacingXXLarge  // 32px
```

### 动画

```qml
Theme.animationDurationFast    // 150ms
Theme.animationDurationMedium  // 250ms
Theme.animationDurationSlow    // 350ms
```

---

## 文件结构

```
qml/component/
├── Theme.qml            # 主题配置
├── FluentIconGlyph.qml  # 图标定义
├── QDButton.qml         # 按钮
├── QDTextField.qml      # 输入框
├── QDCheckBox.qml       # 复选框
├── QDSwitch.qml         # 开关
├── QDSlider.qml         # 滑块
├── QDComboBox.qml       # 下拉框
├── QDCard.qml           # 卡片
├── QDDialog.qml         # 对话框
├── QDToast.qml          # 消息提示
├── QDProgressBar.qml    # 进度条
├── QDBadge.qml          # 徽章
├── QDDivider.qml        # 分割线
├── QDToolTip.qml        # 工具提示
├── qmldir               # 模块定义
└── README.md            # 本文档
```
