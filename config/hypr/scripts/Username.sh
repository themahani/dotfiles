#!/usr/bin/env bash

echo $(getent passwd $USER | awk -F: '{print $5}')
