// Modern Fluent Design Theme
// Singleton for global theme configuration
pragma Singleton
import QtQuick

QtObject {
    // ============ Colors ============
    
    // Background Colors
    readonly property color background: "#1E1E1E"           // 深灰背景
    readonly property color surface: "#252525"              // 卡片/表面
    readonly property color surfaceVariant: "#2D2D2D"       // 次级表面
    readonly property color surfaceHover: "#303030"         // 表面悬停
    
    // Primary Colors (Blue)
    readonly property color primary: "#0078D4"              // 主蓝色
    readonly property color primaryHover: "#1084D8"         // 悬停蓝色
    readonly property color primaryPressed: "#005A9E"       // 按下蓝色
    readonly property color primaryDisabled: "#4A4A4A"      // 禁用状态
    
    // Accent Colors
    readonly property color accent: "#60A5FA"               // 亮蓝色强调
    readonly property color accentLight: "#93C5FD"          // 浅蓝色
    
    // Border Colors
    readonly property color border: "#3F3F3F"               // 边框
    readonly property color borderHover: "#505050"          // 悬停边框
    readonly property color borderFocus: "#0078D4"          // 聚焦边框
    
    // Text Colors
    readonly property color text: "#FFFFFF"                 // 主文本
    readonly property color textSecondary: "#B4B4B4"        // 次级文本
    readonly property color textDisabled: "#6B6B6B"         // 禁用文本
    readonly property color textOnPrimary: "#FFFFFF"        // 主色上的文本
    
    // Semantic Colors
    readonly property color success: "#10B981"              // 成功绿
    readonly property color successHover: "#059669"         // 成功悬停
    readonly property color error: "#EF4444"                // 错误红
    readonly property color errorHover: "#DC2626"           // 错误悬停
    readonly property color warning: "#F59E0B"              // 警告橙
    readonly property color warningHover: "#D97706"         // 警告悬停
    readonly property color info: "#3B82F6"                 // 信息蓝
    readonly property color infoHover: "#2563EB"            // 信息悬停
    
    // Shadow & Overlay
    readonly property color shadowLight: "#00000040"        // 浅阴影
    readonly property color shadowMedium: "#00000060"       // 中阴影
    readonly property color shadowDark: "#00000080"         // 深阴影
    readonly property color overlay: "#00000099"            // 遮罩层
    
    // ============ Dimensions ============
    
    // Border Radius
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12
    readonly property int radiusXLarge: 16
    readonly property int radiusFull: 9999
    
    // Spacing
    readonly property int spacingXSmall: 4
    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 12
    readonly property int spacingLarge: 16
    readonly property int spacingXLarge: 24
    readonly property int spacingXXLarge: 32
    
    // Component Sizes
    readonly property int buttonHeightSmall: 28
    readonly property int buttonHeightMedium: 36
    readonly property int buttonHeightLarge: 44
    
    readonly property int iconSizeSmall: 16
    readonly property int iconSizeMedium: 20
    readonly property int iconSizeLarge: 24
    
    // Border Width
    readonly property int borderWidthThin: 1
    readonly property int borderWidthMedium: 2
    
    // ============ Typography ============
    
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 16
    readonly property int fontSizeXLarge: 18
    readonly property int fontSizeTitle: 20
    readonly property int fontSizeHeading: 24
    
    readonly property string fontFamily: "Segoe UI"
    readonly property string fontFamilyMono: "Consolas"
    
    // ============ Animation ============
    
    readonly property int animationDurationFast: 150
    readonly property int animationDurationMedium: 250
    readonly property int animationDurationSlow: 350
    
    readonly property int animationEasingType: Easing.OutCubic
    
    // ============ Z-Index ============
    
    readonly property int zIndexBase: 0
    readonly property int zIndexDropdown: 100
    readonly property int zIndexModal: 200
    readonly property int zIndexToast: 300
    readonly property int zIndexTooltip: 400
}
