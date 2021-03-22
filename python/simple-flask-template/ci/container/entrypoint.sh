#!/bin/bash

export PATH="$PATH:/opt/confd/bin"
confd -onetime -backend env

/usr/bin/supervisord
