Config 
{ font = "xft:inconsolata:size=9" 
, fgColor = "@" 
, bgColor = "@" 
, position = BottomSize C 100 23
, commands = 
  [ Run Battery ["-t", "<left>"] 100 
  , Run MultiCpu ["-t","<total0>"] 30 
  , Run Date "%#A %_d %#B %Y  <fc=@>|</fc>  %H:%M" "date" 600 
  , Run Com "/home/tzbob/bin/alsavolume" [] "volume" 10 
  , Run StdinReader ] 
, sepChar = "%" 
, alignSep = "}{" 
, template = " %StdinReader% }{ <fc=@>cpu</fc>  %multicpu%   <fc=@>vol</fc>  %volume%   <fc=@>bat</fc>  %battery%  <fc=@>|</fc>  %date%  " 
}
