{-# LANGUAGE QualifiedDo #-}

import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Hooks.SetWMName
import XMonad.Util.EZConfig
import XMonad.Util.Loggers
import XMonad.Util.Ungrab
import XMonad.Util.SpawnOnce

import qualified XMonad.StackSet as W

myBorderWidth = 1
myWorkspaces  = ["1", "2","3","4","5","6","7","8","9","0"]

-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor  = "#585b70"
myFocusedBorderColor = "#cba6f7"

myStartupHook :: X ()
myStartupHook = do
  spawn "killall conky"                    -- kill current conky on each restart
  spawnOnce "picom"
  spawnOnce "nm-applet"
  spawnOnce "volumeicon"
  spawnOnce "notify-log $HOME/.log/notify.log"
  spawnOnce "sleep 2 && xmonad --restart"
  -- spawn "~/.config/polybar/launch.sh"
  spawnOnce "firefox"
  spawnOnce "discord"
  spawnOnce "whatsdesk"
  spawnOnce "todoist"
  setWMName "LG3D"

-- myManageHook =  composeAll
--     [
--       className =? "Exe"                              --> doFullFloat -- chrome flash
--     , className =? "Firefox"                          --> doShift "6"
--     , className =? "firefox"                          --> doShift "6"
--     , className =? "Peek"                             --> doFloat
--     , className =? "Plugin-container"                 --> doFullFloat -- firefox chrome flash
--     , className =? "Spotify"                          --> doShift "0"
--     , className =? "spotify"                          --> doShift "0"
--     , className =? "Thunderbird"                      --> doShift "9"
--     , className =? "zoom"                             --> doShift "0"
--     , resource  =? "feh"                              --> doIgnore
--     , isFullscreen --> doFullFloat
--     ]

myConfig =
  def
    { modMask = mod4Mask, -- Rebind mod to the super key.
      terminal = "st",
      workspaces = myWorkspaces,
      borderWidth = myBorderWidth,
      normalBorderColor  = myNormalBorderColor,
      focusedBorderColor = myFocusedBorderColor
      -- ,startupHook = myStartupHook
      -- ,manageHook = manageDocks <+> myManageHook <+> manageHook def
    }
    `additionalKeysP` 
    [ ("M-p", spawn "~/.config/rofi/scripts/rofi-wrapper.sh run")
      , ("M-o", spawn "~/.config/rofi/scripts/rofi-wrapper.sh options")
      , ("<Print>", spawn "flameshot gui")
      -- Monitor
      , ("M-M1-1", spawn "$HOME/.config/sxhkd/switch-monitor-input.sh 1")
      , ("M-M1-2", spawn "$HOME/.config/sxhkd/switch-monitor-input.sh 2")
      -- Game launcher
      , ("M1-g", spawn "$HOME/.config/rofi/scripts/rofi-wrapper.sh games")
      -- Audio
      , ("<XF86AudioRaiseVolume>", spawn "pulsemixer --change-volume +2")
      , ("<XF86AudioLowerVolume>", spawn "pulsemixer --change-volume -2")
      , ("M-0",   windows $ W.greedyView "0")  -- workspace 0
      , ("M-S-0", (windows $ W.shift "0") >> (windows $W.greedyView "0")) -- shift window to WS 0
      , ("<XF86AudioMute>", spawn "amixer -q set Master toggle")
      , ("<XF86AudioPlay>", spawn "playerctl play-pause")
      , ("<XF86AudioStop>", spawn "playerctl stop")
      , ("<XF86AudioNext>", spawn "playerctl next")
      , ("<XF86AudioPrev>", spawn "playerctl previous")
      -- Bitwarden
      , ("M1-t", spawn "bwmenu --auto-lock -i")
      ]

myXmobarPP :: PP
myXmobarPP = def
    { ppSep             = magenta " • "
    , ppTitleSanitize   = xmobarStrip
    , ppCurrent         = wrap " " "" . xmobarBorder "Top" "#8be9fd" 2
    , ppHidden          = white . wrap " " ""
    , ppHiddenNoWindows = lowWhite . wrap " " ""
    , ppUrgent          = red . wrap (yellow "!") (yellow "!")
    , ppOrder           = \[ws, l, _, wins] -> [ws, l, wins]
    , ppExtras          = [logTitles formatFocused formatUnfocused]
    }
  where
    formatFocused   = wrap (white    "[") (white    "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue    . ppWindow

    -- | Windows should have *some* title, which should not not exceed a
    -- sane length.
    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

    blue, lowWhite, magenta, red, white, yellow :: String -> String
    magenta  = xmobarColor "#ff79c6" ""
    blue     = xmobarColor "#bd93f9" ""
    white    = xmobarColor "#f8f8f2" ""
    yellow   = xmobarColor "#f1fa8c" ""
    red      = xmobarColor "#ff5555" ""
    lowWhite = xmobarColor "#bbbbbb" ""

main :: IO ()
main =
  xmonad
    . ewmhFullscreen
    . ewmh
    . withEasySB (statusBarProp "xmobar ~/.config/xmobar/xmobarrc" (pure myXmobarPP)) defToggleStrutsKey
    $ myConfig
