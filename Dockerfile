FROM centos:latest AS build_env 

# Needed for centos 8 -- mirror are gone :(
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/CentOS-*.repo
RUN sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/CentOS-*.repo
RUN sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/CentOS-*.repo

# install latest C++
RUN yum group install -y "Development Tools"
RUN yum install -y wget
RUN yum install -y patch
RUN yum install -y python3
RUN yum install -y cmake
RUN yum install -y git 

WORKDIR /INSTALL

# Add eigen dependency
RUN git clone https://gitlab.com/libeigen/eigen.git
WORKDIR /INSTALL/eigen 
RUN mkdir build
WORKDIR /INSTALL/eigen/build
RUN cmake ..


# Clone Epigraph
WORKDIR /INSTALL/
RUN git clone --recurse-submodules -j8 https://github.com/EmbersArc/Epigraph.git
WORKDIR /INSTALL/Epigraph
RUN mkdir build
WORKDIR /INSTALL/Epigraph/build

# Build Epigraph + OSQP + ECOS
RUN cmake -DEigen3_DIR=/INSTALL/eigen/build/ -DENABLE_ECOS=TRUE -DENABLE_OSQP=TRUE ..
RUN make
RUN make install

WORKDIR /INSTALL/

# Now that Epigraph is build -- we no longer need cmake, or any files other than source/headers/libs
WORKDIR /INSTALL/
RUN find . \
    -not -name "*.cc" \
    -not -name "*.c" \
    -not -name "*.h" \
    -not -name "*.f" \
    -not -name "*.hpp" \
    -not -name "*.cpp" \
    -not -name "*.cc" \
    -not -name "*.h" \
    -not -name "*.so" \
    -not -name "*.o" \
    -not -name "*.a" \
    -not -name "*.s" \
    -not -name "*.inc" \
    -name "*.*" \
    -type f -exec rm -f {} + 

RUN find . -empty -type d -delete

#RUN /bin/bash -O extglob -c 'rm -f !(*.cc|*.c|*.h|*.f|*.hpp|*.cpp|*.cc|*.h|*.so|*.o|*.a|*.s) || true'


WORKDIR /
COPY test.cc /test.cc
ENV LD_LIBRARY_PATH=/INSTALL//Epigraph/build/solvers/osqp/out/:/INSTALL//Epigraph/build/solvers/ecos/:/INSTALL//Epigraph/build/:/INSTALL//Epigraph/build/solvers/osqp/lin_sys/direct/qdldl/qdldl_sources/out/
RUN g++ -std=c++17 \
    -Dosqp_EXPORTS \
    -DENABLE_ECOS=TRUE \
    -DENABLE_OSQP=TRUE \
    -I/INSTALL/Epigraph/solvers/ecos/include/ \
    -I/INSTALL/Epigraph/solvers/osqp/lin_sys/direct/qdldl \
    -I/INSTALL/Epigraph/solvers/osqp/lin_sys/direct/qdldl/qdldl_sources/include \
    -I/INSTALL/Epigraph/solvers/osqp/lin_sys/direct/pardiso \
    -I/INSTALL/Epigraph/solvers/osqp/include \
    -I/INSTALL/Epigraph/include/ \
    -I/INSTALL/Epigraph/include/wrappers/ \
    -I/INSTALL/Epigraph/solvers/osqp/lin_sys \
    -I/INSTALL/eigen/ \
    -I/INSTALL/Epigraph/solvers/ecos/external/SuiteSparse_config  \
    -L/INSTALL/Epigraph/build/solvers/osqp/out/ \
    -L/INSTALL/Epigraph/build/solvers/ecos/ \
    -L/INSTALL/Epigraph/build/  \
    -lqdldl \
    -lepigraph \
    -losqp \
    -lecos \
    -O3 \
    -fPIC \
    test.cc

RUN ./a.out

RUN cp -r /usr/local/include/qdldl/ /INSTALL/qdldl_include
RUN cp -r /usr/local/include/osqp/ /INSTALL/osqp_include
RUN cp -r /usr/local/include/ecos/ /INSTALL/ecos_include

FROM scratch as copy_env 
COPY --from=build_env /INSTALL . 
CMD ["tail -F /dev/null"]