FROM jupyter/datascience-notebook:julia-1.9.3

USER root

ENV JULIA_NUM_THREADS=24

# Install Git LFS
# https://github.com/git-lfs/git-lfs/blob/main/INSTALLING.md
RUN apt-get update && \
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
    apt-get install -y git-lfs

RUN groupadd -f jovyan && \
    usermod -a -G jovyan jovyan

RUN mkdir -p /home/jovyan/.cursor-server/data/User/globalStorage/julialang.language-julia/lsdepot/v1 && \
    chown -R jovyan:jovyan /home/jovyan/.cursor-server && \
    chmod -R u+rw /home/jovyan/.cursor-server

COPY ./init.jl /home/jovyan/init.jl

USER jovyan

RUN julia /home/jovyan/init.jl
