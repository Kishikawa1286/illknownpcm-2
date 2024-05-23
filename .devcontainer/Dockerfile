FROM jupyter/datascience-notebook:julia-1.9.3

USER root

RUN groupadd -f jovyan && \
    usermod -a -G jovyan jovyan

RUN mkdir -p /home/jovyan/.cursor-server/data/User/globalStorage/julialang.language-julia/lsdepot/v1 && \
    chown -R jovyan:jovyan /home/jovyan/.cursor-server && \
    chmod -R u+rw /home/jovyan/.cursor-server

COPY ./init.jl /home/jovyan/init.jl
RUN julia /home/jovyan/init.jl

COPY ./entrypoint.sh /home/jovyan/entrypoint.sh
RUN chmod +x /home/jovyan/entrypoint.sh
ENTRYPOINT ["/home/jovyan/entrypoint.sh"]

USER jovyan
