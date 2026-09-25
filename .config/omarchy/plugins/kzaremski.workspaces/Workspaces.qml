import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  // Which monitor this bar instance lives on. Widgets are instantiated once
  // per screen, but `bar` is the shared Bar root, so it can't tell us -- the
  // window's own screen can. Empty string means "couldn't tell", and the
  // filter below then falls back to showing everything.
  readonly property string screenName: root.QsWindow && root.QsWindow.window
    && root.QsWindow.window.screen ? root.QsWindow.window.screen.name : ""

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = []
    var values = Hyprland.workspaces.values
    var mine = root.screenName

    // Laptop mode. The pinned 1-5 / 6-10 workspace_rules in hypr/monitors.lua
    // are persistent, and Hyprland creates those workspaces even when the
    // monitor their rule names is absent -- it falls them back onto whatever
    // output does exist. Undocked that means ten slots, seven of them empty.
    // Docked, the pinning is the whole point and every slot stays put.
    var laptopMode = Hyprland.monitors.values.length <= 1
    var focusedId = Hyprland.focusedWorkspace !== null ? Hyprland.focusedWorkspace.id : -1

    for (var i = 0; i < values.length; i++) {
      var ws = values[i]
      var id = ws.id
      if (id <= 0) continue

      var tl = ws.toplevels
      var occupied = tl && tl.values.length > 0
      var isFocused = (id === focusedId)

      // Above 1-10 there is NO keybinding (bindings/tiling.lua only generates
      // SUPER+1..0) and nothing to scroll to, so an occupied workspace 11 would
      // be invisible AND unreachable -- the window is simply lost. Show it
      // whenever it holds something. Empty strays above 10 stay hidden.
      if (id > 10 && !occupied && !isFocused) continue

      // Laptop mode: the pinned 1-5 / 6-10 rules in hypr/monitors.lua are
      // persistent, and Hyprland creates those workspaces even when the monitor
      // their rule names is absent, falling them back onto whatever output
      // exists. Undocked that would be ten mostly-empty slots. Docked, the
      // pinning is the point and every slot stays. The focused one is kept even
      // when empty so the bar never goes blank and scrolling has a position to
      // move from.
      if (laptopMode && !occupied && !isFocused) continue

      // Only workspaces living on this monitor. Hyprland moves a workspace
      // between monitors as you focus it, and this list re-evaluates because
      // Hyprland.workspaces.values is reactive.
      var mon = ws.monitor ? ws.monitor.name : ""
      if (mine !== "" && mon !== "" && mon !== mine) continue

      if (ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  // --- scroll-to-switch -----------------------------------------------------
  // Accumulate wheel delta so a trackpad's many small events don't fire a
  // workspace change per pixel. 120 units = one notch on a normal mouse.
  property int wheelAccum: 0

  function cycleWorkspace(step) {
    var ids = root.workspaceIds()
    if (ids.length === 0) return

    var current = Hyprland.focusedWorkspace !== null ? Hyprland.focusedWorkspace.id : ids[0]
    var idx = ids.indexOf(current)
    if (idx === -1) idx = 0

    var next = idx + step
    // Clamp rather than wrap: scrolling off the end shouldn't jump you across
    // the whole bar. Change to a modulo here if you prefer wrapping.
    if (next < 0) next = 0
    if (next > ids.length - 1) next = ids.length - 1

    if (ids[next] !== current) root.focusWorkspace(ids[next])
  }

  // Cached so the UI can bind to a real property. `model: workspaceIds()` only
  // re-evaluates when a property it READ changes -- and when a monitor is
  // unplugged Hyprland mutates each workspace's `monitor` field in place,
  // which the binding never notices. The bar then kept showing the old
  // monitor's workspaces until something else forced a re-read (cycling
  // through workspaces, which finally changed Hyprland.workspaces.values).
  // Refreshing off rawEvent is the pattern Omarchy's own KeyboardLayout uses.
  property var wsIds: []

  function refreshWorkspaces() {
    root.wsIds = root.workspaceIds()
  }

  Component.onCompleted: root.refreshWorkspaces()

  // screenName is a binding on QsWindow; when it resolves or changes (the bar
  // moving to a different output) the cached list has to be rebuilt too.
  onScreenNameChanged: root.refreshWorkspaces()

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event || !event.name) return
      var name = String(event.name)
      // monitoradded / monitorremoved / focusedmon, plus the workspace
      // lifecycle events (createworkspace, destroyworkspace, moveworkspace).
      if (name.indexOf("monitor") !== -1
          || name.indexOf("workspace") !== -1
          || name === "focusedmon"
          || name === "openwindow"
          || name === "closewindow"
          || name === "movewindow"
          || name === "configreloaded") {
        root.refreshWorkspaces()
      }
    }
  }

  Connections {
    target: Hyprland.workspaces
    function onValuesChanged() { root.refreshWorkspaces() }
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : Math.max(1, root.wsIds.length)
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.wsIds

      WidgetButton {
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        bar: root.bar
        text: focused ? "\uDB85\uDCFB" : (modelData === 10 ? "0" : String(modelData))
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }
      }
    }
  }

  // acceptedButtons: Qt.NoButton means this receives wheel events but lets
  // clicks fall through to the WidgetButtons underneath, so tapping a
  // workspace still works.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    onWheel: function(wheel) {
      var d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
      if (d === 0) return
      if ((d > 0) !== (root.wheelAccum > 0)) root.wheelAccum = 0
      root.wheelAccum += d
      while (root.wheelAccum >= 120) { root.wheelAccum -= 120; root.cycleWorkspace(-1) }
      while (root.wheelAccum <= -120) { root.wheelAccum += 120; root.cycleWorkspace(1) }
    }
  }


}
