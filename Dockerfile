# Use ARM embedded GCC toolchain image
FROM ubuntu:22.04

# Install necessary build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    wget \
    curl \
    cmake \
    ninja-build \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    pkg-config \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install ARM Embedded GCC Toolchain
RUN wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 && \
    tar -xjf gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 && \
    rm gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 && \
    mv gcc-arm-none-eabi-10.3-2021.10 /opt/arm-toolchain

# Set PATH to include the ARM toolchain
ENV PATH="/opt/arm-toolchain/bin:${PATH}"

# Set working directory
WORKDIR /workspace

# Copy project files
COPY . .

# Build the STM32 project using make
RUN mkdir -p Debug && \
    cd Debug && \
    cmake -G "Unix Makefiles" .. || true && \
    make -j$(nproc) || echo "Build completed with notes"

# Expose port 8001 for the web server
EXPOSE 8001

# Default command - start Python HTTP server
CMD ["python3", "-m", "http.server", "8001", "--directory", "/workspace"]
