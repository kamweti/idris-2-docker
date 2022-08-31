FROM debian:bullseye as scheme-builder

WORKDIR /root

RUN apt-get update && \
    apt-get install -y git make gcc libncurses5-dev libncursesw5-dev libx11-dev libgmp-dev

COPY scripts/install-chezscheme-arch.sh ./install-chezscheme-arch.sh 

# check if system is arm based
# if so, install chez scheme from source

RUN if [ $(uname -m) = "aarch64" ] ; then ./install-chezscheme-arch.sh ; else apt-get install -y chezscheme ; fi
RUN which scheme

# copy csv9.5* to /root/move
# this makes it a bit easier for us to move the csv folder to other build steps, since it is necessary for scheme to run
RUN mkdir move && cp -r /usr/lib/csv9.5* /root/scheme-lib 

FROM debian:bullseye as idris-builder

RUN apt-get update && \
    apt-get install -y git make gcc libgmp-dev

ENV IDRIS2_CG racket
ENV DEBIAN_FRONTEND noninteractive
ARG IDRIS_VERSION

COPY --from=scheme-builder /usr/bin/scheme /usr/bin/scheme
# copy csv9.5* to /usr/lib, and also to /root/move for easier access for other build steps
COPY --from=scheme-builder /root/scheme-lib/ /usr/lib/
COPY --from=scheme-builder /root/scheme-lib /root/scheme-lib 

WORKDIR /root
# if IDRIS_VERSION is 'latest', do not switch to a branch
RUN if [ $IDRIS_VERSION = "latest" ] ; \ 
    then git clone --depth 1 https://github.com/idris-lang/Idris2.git ; \
    else git clone --depth 1 --branch $IDRIS_VERSION https://github.com/idris-lang/Idris2.git ; \
    fi

WORKDIR /root/Idris2 
RUN make bootstrap SCHEME=scheme
RUN make install