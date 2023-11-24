#!/bin/bash

if [ -f /etc/bashrc ]; then
  \. /etc/bashrc
fi

if [ -f ~/.profile.d/lib/bashrc ]; then
  \. ~/.profile.d/lib/bashrc
fi
