FROM ubuntu:latest

RUN apt update && \
    apt install --no-install-recommends -y \
        texlive-xetex \
        texlive-latex-extra \
        texlive-lang-english \
        texlive-lang-european \
        texlive-fonts-recommended \
        texlive-plain-generic \
        fonts-freefont-ttf \
        librsvg2-bin \
        netbase \
        plantuml \
        pandoc \
        pandoc-citeproc \
        python3-minimal \
        python3-dev \
        python3-pip \
        python3-setuptools \
        gcc && \
    pip3 install --no-cache-dir \
        pandoc-fignos \
        pandoc-tablenos \
        pandoc-plantuml-filter && \
    apt remove -y --auto-remove python3-pip && \
    apt purge -y --auto-remove \
        python3-dev \
        python3-setuptools \
        gcc && \
    mkdir -p /appdata && adduser --disabled-password --disabled-login appuser

# necessary step to accept Microsoft's EULA programatically
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
RUN apt install ttf-mscorefonts-installer -y
RUN rm -rf /var/lib/apt/lists/* 

WORKDIR /appdata

ARG CSL_URL="https://www.zotero.org/styles/haaga-helia-university-of-applied-sciences-harvard"
ARG CSL_SHA256="1e483484f2dd99ebf7c2fe204c6e05788f7eee47a2275daa71997923e916b75c"

COPY media/*.png ./media/
ADD $CSL_URL ./style.csl
COPY hhtemplate.tex references.md ./

RUN \
    # Grant access rights for the appuser
    chmod -R a+r /appdata && chown appuser:appuser /appdata \
    # Ensure integrity of the CSL file
    && [ "$(sha256sum style.csl | cut -d' ' -f1)" = $CSL_SHA256 ]

USER appuser

ENTRYPOINT [ "pandoc", "+RTS", "-M128m", "-RTS", "--template=/appdata/hhtemplate.tex", "--filter=pandoc-tablenos", "--filter=pandoc-fignos", "--filter=pandoc-citeproc", "--filter=pandoc-plantuml", "--pdf-engine=xelatex", "--listings", "--variable=hhreportlogopath:/appdata/media/hhreportlogo.png", "--variable=hhdocumentfont:FreeSans", "--csl=/appdata/style.csl", "--resource-path=/appdata:/report:." ]
