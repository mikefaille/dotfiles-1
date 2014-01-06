import XMonad
import Data.Monoid
import System.Exit
import System.IO

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.SetWMName
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.EwmhDesktops
import XMonad.Actions.UpdatePointer

import XMonad.Layout.NoBorders
import XMonad.Layout.Spacing
import XMonad.Layout.ResizableTile
import XMonad.Layout.Named

import XMonad.Util.NamedScratchpad
import XMonad.Util.Run
import XMonad.Util.Paste

import qualified XMonad.StackSet as W
import qualified Data.Map as M

data ColorScheme = ColorScheme
  { foreground :: String
  , background :: String
  , empty :: String
  , hidden :: String
  , highlight :: String 
  , seperator :: String }

scheme :: ColorScheme
scheme = ColorScheme
  { foreground = "#efefef"
  , background = "#6e839c"
  , empty = "#666666"
  , hidden = "#aaaaaa"
  , highlight = "#efefef" 
  , seperator = "#bcb1b7" }

-- Key bindings. Add, modify or remove key bindings here.
-------------------------------------------------------------------------------
myKeys :: XConfig l -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
  [ ((modm .|. shiftMask, xK_c), kill)

  , ((modm, xK_space ), sendMessage NextLayout)

  , ((modm, xK_j), windows W.focusDown)
  , ((modm, xK_k), windows W.focusUp)

  , ((modm, xK_Return), windows W.swapMaster)
  , ((modm .|. shiftMask, xK_j), windows W.swapDown)
  , ((modm .|. shiftMask, xK_k), windows W.swapUp)

  , ((modm, xK_h), sendMessage Shrink)
  , ((modm, xK_l), sendMessage Expand)
  , ((modm, xK_u), sendMessage MirrorShrink)
  , ((modm, xK_i), sendMessage MirrorExpand)

  , ((modm, xK_t), withFocused $ windows . W.sink)

  , ((modm .|. shiftMask, xK_h), sendMessage (IncMasterN 1))
  , ((modm .|. shiftMask, xK_l), sendMessage (IncMasterN (-1)))

  , ((modm .|. controlMask , xK_j), spawn "amixer -q set Master 5- unmute")
  , ((modm .|. controlMask , xK_k), spawn "amixer -q set Master 5+ unmute")
  , ((modm .|. controlMask , xK_m), spawn "amixer set Master toggle")

  , ((modm, xK_c), sendMessage ToggleStruts)

  , ((modm, xK_q), spawn "xmonad --recompile; xmonad --restart")
  , ((0, xK_Insert), pasteSelection)

  -- Programs
  , ((modm .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)
  , ((modm, xK_p), spawn dmenuCmd)
  , ((modm, xK_b), spawn "chromium")
  , ((modm, xK_g), spawn "gvim")
  , ((modm, xK_x), spawn "~/scala-ide/eclipse")
  , ((modm .|. shiftMask, xK_t), namedScratchpadAction myScratchpads "term")
  , ((modm .|. shiftMask, xK_n), namedScratchpadAction myScratchpads "keep")
  , ((modm .|. shiftMask, xK_b), spawn "~/Dropbox/Scala/snapdim/target/start") ]
    ++ workspaceKeys ++ monitorKeys
  where
    dmenuCmd = "dmenu_run"
      ++ " -nb \"" ++ (background scheme) ++ "\""
      ++ " -nf \"" ++ (foreground scheme) ++ "\""
      ++ " -sf \"" ++ (highlight scheme) ++ "\""
    workspaceKeys =
      [((m .|. modm, k), windows $ f i)
          | (i, k) <- zip (XMonad.workspaces conf) [xK_a, xK_s, xK_d, xK_f, xK_z]
          , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    monitorKeys =
      [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
          | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
          , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

-- Mouse bindings: default actions bound to mouse events
-------------------------------------------------------------------------------
myMouseBindings :: XConfig l -> M.Map (KeyMask, Button) (Window -> X ())
myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList
  [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster))
  , ((modm, button2), (\w -> focus w >> windows W.shiftMaster))
  , ((modm, button3), (\w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster)) ]

-- Layouts
------------------------------------------------------------------------
myLayout = smartBorders $ spacing 1 $ avoidStruts $ tiled ||| max
  where
    tiled = named "Tall" $ ResizableTall 1 (3/100) (3/5) []
    max = named "Max" Full

-- Window rules:
-- > xprop | grep WM_CLASS
-------------------------------------------------------------------------------
myManageHook = manageDocks <+> composeAll
    [ isFullscreen --> doFullFloat ] 
      <+> namedScratchpadManageHook myScratchpads

-- Scratchpads
-------------------------------------------------------------------------------
myScratchpads = [ NS "term" spawnTerm findTerm managePad
                , NS "keep" spawnKeep findKeep managePad ]
  where
    managePad = customFloating $ W.RationalRect l t w h
      where 
        h = 0.7       -- height, 70% 
        w = 0.5       -- width,  50%
        t = (1 - h)/2 -- centered left/right
        l = (1 - w)/2 -- centered left/right
    spawnTerm = "termite -t termite-scratchpad"
    findTerm = title =? "termite-scratchpad"
    spawnKeep = "chromium --app=https://drive.google.com/keep"
    findKeep = resource =? "drive.google.com__keep"

-- Status bars and logging
-------------------------------------------------------------------------------
addPad :: String -> String
addPad = wrap " " " "

colorizer :: (ColorScheme -> String) -> (String -> String)
colorizer getter = xmobarColor (getter scheme) (background scheme)

myPP :: Handle -> PP
myPP statusPipe = namedScratchpadFilterOutWorkspacePP xmobarPP 
  { ppOutput = hPutStrLn statusPipe
  , ppCurrent = colorizer highlight . addPad
  , ppHiddenNoWindows = colorizer empty . addPad
  , ppHidden = colorizer hidden . addPad
  , ppTitle = colorizer foreground
  , ppSep = (colorizer seperator) "  |  " }

-- Run xmonad with the settings specified. No need to modify this.
-------------------------------------------------------------------------------
main :: IO ()
main = do
  writeFile "debugpoop" "test this shit"
  bar <- spawnPipe "xmobar ~/.xmonad/xmobar.hs"
  xmonad $ ewmh defaultConfig 
    { terminal           = "termite"
    , focusFollowsMouse  = True
    , borderWidth        = 0
    , modMask            = mod4Mask
    , workspaces         = ["A", "S", "D", "F", "Z"]

    -- bindings
    , keys               = myKeys
    , mouseBindings      = myMouseBindings

    -- hooks, layouts
    , layoutHook         = myLayout
    , manageHook         = myManageHook
    , handleEventHook    = fullscreenEventHook
    , logHook            = dynamicLogWithPP (myPP bar) >> updatePointer (Relative 0.5 0.5)
    , startupHook        = setWMName "LG3D" }
