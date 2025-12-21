@echo off
git status > git_state.txt
echo --- >> git_state.txt
git branch -vv >> git_state.txt
echo --- >> git_state.txt
git log -n 1 >> git_state.txt
