#!/bin/bash -eux

# Simple script for setting up all toolchain dependencies for building Helium on macOS

brew install ninja coreutils ccache --overwrite

# Install Python dependencies from PyPI
pip3 install httplib2 requests pillow --break-system-packages
