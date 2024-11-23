FROM redhat/ubi9 AS build_env 

RUN dnf install -y wget g++ gcc patch python3 cmake git

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
    -not -name "*LICENSE*" \
    -name "*.*" \
    -type f -exec rm -f {} + 

RUN find . -empty -type d -delete

WORKDIR /

FROM scratch as copy_env 
COPY --from=build_env /INSTALL . 

# So users can inspect the environment.
CMD ["tail -F /dev/null"]