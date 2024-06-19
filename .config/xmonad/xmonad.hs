{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE QualifiedDo #-}

import Control.Monad (join, when)
import Data.Maybe (maybeToList)
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.Focus
import XMonad.Layout.NoBorders
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.WindowSwallowing
import XMonad.StackSet qualified as W
import XMonad.Util.EZConfig
import XMonad.Util.Hacks (javaHack, trayAbovePanelEventHook, trayPaddingEventHook, trayPaddingXmobarEventHook, trayerAboveXmobarEventHook, trayerPaddingXmobarEventHook, windowedFullscreenFixEventHook)
import XMonad.Util.Loggers
import XMonad.Util.SpawnOnce
import XMonad.Operations
import Data.Semigroup
import XMonad.Hooks.OnPropertyChange

myBorderWidth = 1

myNormalBorderColor = "#585b70"

myFocusedBorderColor = "#cba6f7"

addNETSupported :: Atom -> X ()
addNETSupported x   = withDisplay $ \dpy -> do
    r               <- asks theRoot
    a_NET_SUPPORTED <- getAtom "_NET_SUPPORTED"
    a               <- getAtom "ATOM"
    liftIO $ do
       sup <- (join . maybeToList) <$> getWindowProperty32 dpy a_NET_SUPPORTED r
       when (fromIntegral x `notElem` sup) $
         changeProperty32 dpy r a_NET_SUPPORTED a propModeAppend [fromIntegral x]

addEWMHFullscreen :: X ()
addEWMHFullscreen   = do
    wms <- getAtom "_NET_WM_STATE"
    wfs <- getAtom "_NET_WM_STATE_FULLSCREEN"
    mapM_ addNETSupported [wms, wfs]

myStartupHook :: X ()
myStartupHook = do
  -- spawn "killall conky" -- kill current conky on each restart
  spawn "killall trayer" -- kill current conky on each restart
  spawnOnce "picom"
  spawnOnce "nm-applet"
  spawnOnce "volumeicon"
  spawnOnce "blueman-applet"
  spawnOnce "notify-log $HOME/.log/notify.log"
  -- spawn "~/.config/polybar/launch.sh"
  spawnOnce "firefox"
  -- spawnOnce "trayer --edge top --align right --SetDockType true --SetPartialStrut true --expand true --widthtype request --tint 0x002b36 --height 20 --alpha 0 --monitor 1 --transparent true -l"
  -- spawn "sleep 2 && trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 1 --transparent true --alpha 0 --height 22"
  spawnOnce "feh --bg-scale /home/tobins/Pictures/Backgrounds/3440x1440/JapanStreetNight.jpg --bg-fill /home/tobins/Pictures/Backgrounds/2560x1440/cyber-city-anime-artwork.jpg"
  spawnOnce "xset s 120 120"
  spawnOnce "whatsdesk"
  spawnOnce "thunderbird"
  spawnOnce "spotify"
  spawnOnce "redshift-gtk"
  spawnOnce "kdeconnect-cli --refresh"
  spawnOnce "steam-screensaver-fix-native"
  spawnOnce "barrier"
  spawnOnce "sleep 10 && discord"
  spawnOnce "sleep 2 && conky -c $HOME/.config/conky/macchiato.conf"

  spawn ("sleep 2 && trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 1 --transparent true --alpha 0 --height 22")
  -- spawnOnce "sleep 2 && xmonad --restart"

myWorkspaces = [" 1 <fn=2>\xf111</fn>", "2 <fn=2>\xf111</fn>", "3 <fn=2>\xf111</fn>", "4 <fn=2>\xf111</fn>", "5 <fn=2>\xf111</fn>", "6 <fn=2>\xf111</fn>", "7 <fn=2>\xf111</fn>", "8 <fn=2>\xf111</fn>", "9 <fn=2>\xf111</fn>", "10 <fn=2>\xf111</fn>"]

myWorkspaceSelected number =
  myWorkspaces !! (number - 1)

myManageHook =
  composeAll
    [ className =? "Exe" --> doFullFloat, -- chrome flash
      className =? "firefox" --> doShift (myWorkspaceSelected 6),
      className =? "Peek" --> doFloat,
      className =? "Barrier" --> doFloat,
      className =? "leagueclientux.exe" --> doFloat,
      className =? "riotclientux.exe" --> doFloat,
      className =? "Plugin-container" --> doFullFloat, -- firefox chrome flash
      className =? "spotify" --> doShift (myWorkspaceSelected 10),
      className =? "Spotify" --> doShift (myWorkspaceSelected 10),
      className =? "Todoist" --> doShift (myWorkspaceSelected 7),
      className =? "discord" --> doShift (myWorkspaceSelected 8),
      className =? "whatsdesk" --> doShift (myWorkspaceSelected 8),
      className =? "thunderbird" --> doShift (myWorkspaceSelected 9),
      appName =? "Blish HUD" --> doIgnore,
      resource =? "feh" --> doIgnore,
      isFullscreen --> doFullFloat
    ]

-- myHandleEventHook :: Event -> X All
-- myHandleEventHook = dynamicPropertyChange "WM_NAME" (title =? "Spotify" --> doShift (myWorkspaceSelected 10))
myHandleEventHook = windowedFullscreenFixEventHook <> swallowEventHook (className =? "Alacritty"  <||> className =? "st-256color" <||> className =? "XTerm") (return True) <> trayerPaddingXmobarEventHook

myConfig =
  def
    { modMask = mod4Mask, -- Rebind mod to the super key.
      terminal = "st",
      workspaces = myWorkspaces,
      borderWidth = myBorderWidth,
      normalBorderColor = myNormalBorderColor,
      focusedBorderColor = myFocusedBorderColor,
      startupHook = myStartupHook >> addEWMHFullscreen,
      manageHook = myManageHook
      ,handleEventHook = myHandleEventHook
    }
    `additionalKeysP` [ ("M-p", spawn "~/.config/rofi/scripts/rofi-wrapper.sh run"),
                        ("M-o", spawn "~/.config/rofi/scripts/rofi-wrapper.sh options"),
                        ("<Print>", spawn "flameshot gui"),
                        -- Monitor
                        ("M-M1-1", spawn "$HOME/.scripts/switch-monitor-input.sh 1"),
                        ("M-M1-2", spawn "$HOME/.scripts/switch-monitor-input.sh 2"),
                        -- Game launcher
                        ("M1-g", spawn "$HOME/.config/rofi/scripts/rofi-wrapper.sh games"),
                        ("M1-c", spawn "st -e sh -c '~/.scripts/tmux-launch.sh'"),
                        -- Audio
                        ("<XF86AudioRaiseVolume>", spawn "pulsemixer --change-volume +2"),
                        ("<XF86AudioLowerVolume>", spawn "pulsemixer --change-volume -2"),
                        ("M-0", windows $ W.greedyView (myWorkspaces !! 9)), -- workspace 0
                        ("M-S-0", (windows $ W.shift (myWorkspaces !! 9)) >> (windows $ W.greedyView (myWorkspaces !! 9))), -- shift window to WS 0
                        ("<XF86AudioMute>", spawn "amixer -q set Master toggle"),
                        ("<XF86AudioPlay>", spawn "playerctl play-pause"),
                        ("<XF86AudioStop>", spawn "playerctl stop"),
                        ("<XF86AudioNext>", spawn "playerctl next"),
                        ("<XF86AudioPrev>", spawn "playerctl previous"),
                        -- Bitwarden
                        ("M1-t", spawn "bwmenu --auto-lock -i"),
                        ("M1-p", spawn "amixer set Capture toggle")
                      ]

myXmobarPP :: PP
myXmobarPP =
  def
    { ppTitle = xmobarColor "#89b4fa" "" . shorten 60,
      -- , ppCurrent = xmobarColor "#f38ba8" "" . wrap
      --    ("<box type=Bottom width=2 mb=2 color=#585b70>") "</box>"
      ppCurrent = xmobarColor "#cba6f7" "" . wrap "" "",
      ppHidden = xmobarColor "#6c7086" "" . wrap "" "",
      ppVisible = xmobarColor "#6c7086" "" . wrap "" "",
      ppSep = "<fc=#585b70> | </fc>",
      ppHiddenNoWindows = xmobarColor "#313244" ""
    }

xmobarLeft = statusBarProp "xmobar -x 0 ~/.config/xmobar/xmobarrc" (pure myXmobarPP)
xmobarRight = statusBarProp "xmobar -x 1 ~/.config/xmobar/xmobarrc" (pure myXmobarPP)

main :: IO ()
main = do
        let ah :: ManageHook
            ah = not <$> (className =? "Firefox" <||> className =? "Firefox-esr" <||> className =? "hearthstonedecktracker.exe" <||> className =? "*hearthstonedecktracker*" <||> className =? "HearthstoneOverlay")
                    --> activateSwitchWs
            xcf = setEwmhActivateHook ah
                . ewmhFullscreen
                . ewmh 
                . withEasySB (xmobarLeft <> xmobarRight) defToggleStrutsKey 
                $ myConfig
        xmonad xcf