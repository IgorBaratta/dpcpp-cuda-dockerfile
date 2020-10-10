FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install -y git
RUN apt-get install -y ninja-build
RUN apt-get install -y g++
RUN apt-get install -y python3
RUN apt-get install -y python3-pip
RUN apt-get install -y software-properties-common

RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test
RUN apt-get update

RUN python3 -m pip install cmake

RUN  apt -y install wget
WORKDIR /tmp

# install Intel OpenCL drivers from downloaded package
RUN mkdir -p /opt/intel/oclcpuexp-2020.11.8.0.27_rel
RUN cd /opt/intel/oclcpuexp-2020.11.8.0.27_rel &&\
    wget -q https://github.com/intel/llvm/releases/download/2020-WW36/oclcpuexp-2020.11.8.0.27_rel.tar.gz && \
    tar -zxvf oclcpuexp-2020.11.8.0.27_rel.tar.gz

# Create ICD file pointing to the new runtime
RUN mkdir -p /etc/OpenCL/vendors
RUN echo /opt/intel/oclcpuexp-2020.11.8.0.27_rel/x64/libintelocl.so > /etc/OpenCL/vendors/intel_expcpu.icd

# Extract TBB libraries
RUN mkdir -p /opt/intel/tbb-2021 && cd /opt/intel/tbb-2021 && \
    wget -q https://github.com/oneapi-src/oneTBB/releases/download/v2021.1-beta08/oneapi-tbb-2021.1-beta08-lin.tgz && \
    tar -zxvf oneapi-tbb-2021.1-beta08-lin.tgz


# Copy files from or create symbolic links to TBB libraries in OpenCL RT folder
RUN ln -s /opt/intel/tbb-2021/tbb/lib/intel64/gcc4.8/libtbb.so /opt/intel/oclcpuexp-2020.11.8.0.27_rel/x64
RUN ln -s /opt/intel/tbb-2021/tbb/lib/intel64/gcc4.8/libtbbmalloc.so /opt/intel/oclcpuexp-2020.11.8.0.27_rel/x64
RUN ln -s /opt/intel/tbb-2021/tbb/lib/intel64/gcc4.8/libtbb.so.2 /opt/intel/oclcpuexp-2020.11.8.0.27_rel/x64
RUN ln -s /opt/intel/tbb-2021/tbb/lib/intel64/gcc4.8/libtbbmalloc.so.2 /opt/intel/oclcpuexp-2020.11.8.0.27_rel/x64    

# Configure library paths
RUN echo /opt/intel/oclcpuexp-2020.11.8.0.27_rel/x64 >>  /etc/ld.so.conf.d/libintelopenclexp.conf
RUN ldconfig -f /etc/ld.so.conf.d/libintelopenclexp.conf

ENV DEBIAN_FRONTEND=noninteractive
# Install Cuda 10.2
RUN apt update && add-apt-repository ppa:graphics-drivers
RUN apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
RUN bash -c 'echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list'
RUN bash -c 'echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda_learn.list'
RUN apt update && apt -y install cuda-10-2

RUN export PATH=/usr/local/cuda-10.2/bin${PATH:+:${PATH}} &&\
    export LD_LIBRARY_PATH=/usr/local/cuda-10.2/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}



ENV DPCPP_HOME=/home/sycl_workspace
RUN mkdir $DPCPP_HOME && cd $DPCPP_HOME &&\
    git clone https://github.com/intel/llvm -b sycl

RUN python3 $DPCPP_HOME/llvm/buildbot/configure.py --cuda --no-werror
RUN python3 $DPCPP_HOME/llvm/buildbot/compile.py -j2