FROM nvidia/cuda:13.0.1-devel-ubuntu22.04
# Set environment to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
# Update and install basic tools
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg \
    software-properties-common \
    sudo \
    git \
    lsb-release \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install CMake 3.30+ from Kitware APT repository
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
    gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main" | \
    tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
    apt-get update && \
    apt-get install -y cmake && \
    rm -rf /var/lib/apt/lists/*
    
# Install X11 and OpenGL libraries (Step 3 & 5 combined)
RUN apt-get update && apt-get install -y \
    libxrandr-dev \
    libxinerama-dev \
    libxcursor-dev \
    libxi-dev \
    libxext-dev \
    libxfixes-dev \
    libgl1-mesa-dev \
    libx11-dev \
    libxrender-dev \
    libxcomposite-dev \
    libxdamage-dev \
    libxtst-dev \
    libxss-dev \
    libxmu-dev \
    libxpm-dev \
    && rm -rf /var/lib/apt/lists/*
# Remove old LLVM/Clang and install LLVM 19 (Step 4)
RUN apt-get update && \
    apt-get remove --purge -y clang* llvm* python3-clang* && \
    apt-get autoremove -y && \
    apt-get clean && \
    wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc && \
    echo "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-19 main" | tee /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install -y \
    clang-19 \
    llvm-19 \
    llvm-19-dev \
    llvm-19-tools \
    libomp-19-dev \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*
# Install Intel oneAPI (Step 6)
RUN curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | \
    gpg --dearmor -o /usr/share/keyrings/intel-oneapi-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/intel-oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | \
    tee /etc/apt/sources.list.d/oneAPI.list && \
    apt-get update && \
    apt-get install -y \
    intel-oneapi-mkl-devel \
    intel-oneapi-tbb-devel \
    intel-renderkit \
    && rm -rf /var/lib/apt/lists/*
# Source Intel oneAPI environment and set environment variables
# Note: We need to source setvars.sh and then export the variables
RUN /bin/bash -c "source /opt/intel/oneapi/setvars.sh && \
    echo 'export MKLROOT=${MKLROOT}' >> /etc/environment && \
    echo 'export TBBROOT=${TBBROOT}' >> /etc/environment && \
    echo 'export EMBREE_ROOT=${EMBREE_ROOT}' >> /etc/environment && \
    echo 'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}' >> /etc/environment && \
    echo 'export CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}' >> /etc/environment"
# Add oneAPI initialization to bashrc for interactive shells
RUN echo 'source /opt/intel/oneapi/setvars.sh' >> /etc/bash.bashrc
# Set working directory
WORKDIR /workspace
# Clone and build SuiteSparse
RUN git clone https://github.com/DrTimothyAldenDavis/SuiteSparse.git && \
    cd SuiteSparse && \
    mkdir -p build && \
    cd build && \
    /bin/bash -c "source /opt/intel/oneapi/setvars.sh && \
    cmake -DBLA_VENDOR=Intel10_64lp_seq \
          -DSUITESPARSE_ENABLE_PROJECTS=\"cholmod;umfpack\" \
          -DSUITESPARSE_USE_FORTRAN=OFF \
          -DSUITESPARSE_USE_CUDA=OFF \
          -DCHOLMOD_USE_CUDA=OFF \
          .. && \
    cmake --build . --config Release && \
    cmake --install ."
# Default command
CMD ["/bin/bash"]