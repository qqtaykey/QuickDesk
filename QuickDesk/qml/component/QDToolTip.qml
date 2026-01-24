// Fluent Design ToolTip Component
import QtQuick
import QtQuick.Controls as Controls

Controls.ToolTip {
    id: control
    
    // ============ Custom Properties ============
    
    property int tipDelay: 500
    
    // ============ Size & Style ============
    
    delay: tipDelay
    timeout: 5000
    
    padding: Theme.spacingSmall
    leftPadding: Theme.spacingMedium
    rightPadding: Theme.spacingMedium
    
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeSmall
    
    // ============ Background ============
    
    background: Rectangle {
        color: Theme.surfaceVariant
        border.width: Theme.borderWidthThin
        border.color: Theme.border
        radius: Theme.radiusSmall
        
        // Slight shadow effect
        layer.enabled: true
        layer.effect: ShaderEffect {
            property color shadowColor: Theme.shadowLight
        }
    }
    
    // ============ Content ============
    
    contentItem: Text {
        text: control.text
        font: control.font
        color: Theme.text
        wrapMode: Text.WordWrap
    }
    
    // ============ Animation ============
    
    enter: Transition {
        NumberAnimation { 
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: Theme.animationDurationFast
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            property: "scale"
            from: 0.9
            to: 1.0
            duration: Theme.animationDurationFast
            easing.type: Easing.OutCubic
        }
    }
    
    exit: Transition {
        NumberAnimation { 
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: Theme.animationDurationFast
            easing.type: Easing.InCubic
        }
    }
}
