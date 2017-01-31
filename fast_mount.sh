#!/bin/bash

mkfs.ext4 $1
mount $1  $2
