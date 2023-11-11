import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Util.EZConfig
import XMonad.Util.Loggers
import XMonad.Util.Ungrab

main :: IO ()
main =
  xmonad
    . ewmhFullscreen
    . ewmh
    . withEasySB (statusBarProp "xmobar ~/.config/xmobar/xmobarrc" (pure myXmobarPP)) defToggleStrutsKey
    $ myConfig

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

myConfig =
  def
    { modMask = mod4Mask, -- Rebind mod to the super key.
      terminal = "st"
    }
    `additionalKeysP` 
    [ ("M-p", spawn "~/.config/rofi/scripts/rofi-wrapper.sh run"),
                        ("M-o", spawn "~/.config/rofi/scripts/rofi-wrapper.sh options"),
                        ("<Print>", spawn "flameshot gui"),
                        -- Monitor
                        ("M-M1-1", spawn "$HOME/.config/sxhkd/switch-monitor-input.sh 1"),
                        ("M-M1-2", spawn "$HOME/.config/sxhkd/switch-monitor-input.sh 2"),
                        -- Game launcher
                        ("M1-g", spawn "$HOME/.config/rofi/scripts/rofi-wrapper.sh games"),
                        -- Audio
                        ("<XF86AudioRaiseVolume>", spawn "pulsemixer --change-volume +2"),
                        ("<XF86AudioLowerVolume>", spawn "pulsemixer --change-volume -2"),
                        ("<XF86AudioMute>", spawn "amixer -q set Master toggle"),
                        ("<XF86AudioPlay>", spawn "playerctl play-pause"),
                        ("<XF86AudioStop>", spawn "playerctl stop"),
                        ("<XF86AudioNext>", spawn "playerctl next"),
                        ("<XF86AudioPrev>", spawn "playerctl previous"),
                        -- Bitwarden
                        ("M1-t", spawn "bwmenu --auto-lock -i")
                      ]
