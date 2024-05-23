#!/bin/bash
export JULIA_NUM_THREADS=$(nproc)
exec "$@"
