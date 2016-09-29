#!/bin/sh
set -ex
cd "`dirname $0`"
scp zsavgam.cgi coliseum:www/toastball.net/games/
scp index.html coliseum:www/toastball.net/games/home/
ssh coliseum backup
