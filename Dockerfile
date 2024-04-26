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
        python3 \
        python3-pip \
        python3-setuptools \
        gcc

# necessary step to accept Microsoft's EULA programatically
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections && \
    apt install ttf-mscorefonts-installer -y

RUN apt install -y git && pip install --no-cache-dir --break-system-packages \
        git+https://github.com/tomduck/pandoc-xnos@284474574f51888be75603e7d1df667a0890504d#egg=pandoc-xnos \
        pandoc-plantuml-filter

RUN apt remove -y --auto-remove python3-pip && \
    apt purge -y --auto-remove \
        python3-setuptools \
        gcc && \    
    rm -rf /var/lib/apt/lists/* 

RUN mkdir -p /appdata && adduser --disabled-password --disabled-login appuser

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

ENTRYPOINT [ "pandoc", "--template=/appdata/hhtemplate.tex", "--citeproc", "--pdf-engine=xelatex", "--listings", "--variable=hhreportlogopath:/appdata/media/hhreportlogo.png", "--csl=/appdata/style.csl", "--resource-path=/appdata:/report:." ]
