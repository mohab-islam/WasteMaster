@echo off
echo STARTING DEBUG > debug_output.txt
ver >> debug_output.txt
echo CHECKING NODE >> debug_output.txt
where node >> debug_output.txt
node -v >> debug_output.txt
echo END DEBUG >> debug_output.txt
