#!/bin/bash

\. ~/.profile.d/lib/include

__profile_d_load_stage__ hooks/pre-init
__profile_d_load_stage__ hooks/init
__profile_d_load_stage__ hooks/post-init
