#!/bin/bash
DIR=/home/pinar

# Create .local folder
mkdir $DIR/.local

# Download NVME and LIBURING
cd $DIR/.local

git clone https://github.com/linux-nvme/nvme-cli.git
cd nvme-cli
meson setup --force-fallback-for=libnvme .build
meson compile -C .build
meson install -C .build
cd ..

git clone https://github.com/axboe/liburing.git
cd liburing
./configure --cc=gcc --cxx=g++
make -j$(nproc)
make install
cd ..

echo 'alias nvme="$HOME/.local/nvme-cli/.build/nvme"' >> $DIR/.bashrc
echo 'export PATH=$PATH:~/.local/nvme-cli/.build' >> $DIR/.bashrc
echo 'export LIBURING_INCLUDE_DIR=~/.local/liburing/src/include' >> $DIR/.bashrc

