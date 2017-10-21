@echo off
cd bin
@echo ----- nodejs ------
node test.js
@echo ----- hl ------
hl test.hl
@echo ----- neko ------
neko test.n
start test.swf
pause
