-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Re-apply the display rules when a monitor appears or vanishes.
--
-- monitors.lua picks the workspace split from which VE248 serials are attached,
-- but Hyprland only evaluates that at config load. This dock drops a panel as
-- it heats up, which leaves 6-10 pinned to a monitor that is gone: still
-- holding their windows, still answering SUPER+6..0, displayed nowhere.
--
-- The watcher listens on Hyprland's event socket and reloads once the hotplug
-- stream settles, so the surviving panel takes all ten on its own -- and the
-- split is restored when the second one comes back.
--
-- exec_on_start rather than launch_on_start: the latter wraps the command in
-- `uwsm-app --`, which is for launching applications, not a small daemon.
o.exec_on_start("omarchy-monitor-watch")
