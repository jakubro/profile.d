#!/bin/bash

if [ -f /etc/bashrc ]; then
  \. /etc/bashrc
fi

if [ -f ~/.profile.d/lib/src/bashrc ]; then
  \. ~/.profile.d/lib/src/bashrc
fi
