FROM circleci/python:3.7.4-stretch

USER circleci
WORKDIR /home/circleci
ENV HOME="/home/circleci"
ENV SUBJECTS_DIR="${HOME}/mne_data/MNE-sample-data/subjects"
ENV DISPLAY=":99"
ENV OPENBLAS_NUM_THREADS="4"
ENV MNE_ROOT="${HOME}/minimal_cmds"
ENV PATH="${HOME}/.local/bin/:${MNE_ROOT}/bin:${PATH}"
RUN curl https://staff.washington.edu/larsoner/minimal_cmds.tar.gz | tar xz
ENV LD_LIBRARY_PATH="${MNE_ROOT}/lib:$LD_LIBRARY_PATH"
ENV NEUROMAG2FT_ROOT="${HOME}/minimal_cmds/bin"

RUN neuromag2ft --version

RUN sudo apt-get update && sudo apt-get install --yes qt5-default

RUN git clone git://github.com/mne-tools/mne-python.git
WORKDIR /home/circleci/mne-python
RUN pip install --user --upgrade --progress-bar off pip numpy vtk
RUN pip install --user --upgrade --progress-bar off -r requirements.txt
RUN pip install --user --upgrade --progress-bar off ipython sphinx_fontawesome sphinx_bootstrap_theme memory_profiler
RUN pip install --user --upgrade "https://api.github.com/repos/sphinx-gallery/sphinx-gallery/zipball/master"
RUN pip install --user --upgrade "https://api.github.com/repos/nipy/PySurfer/zipball/master"
RUN pip install --user -e .

RUN python -c "import mne; mne.datasets._download_all_example_data()";

RUN echo "#!/bin/bash" >> start_services.sh
RUN echo "/sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_99.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :99 -screen 0 1400x900x24 -ac +extension GLX +render -noreset " >> start_services.sh
RUN chmod +x start_services.sh

RUN /bin/bash start_services.sh && python -c "import mne; mne.sys_info()" && \
	python -c "from mayavi import mlab; import matplotlib.pyplot as plt; mlab.figure(); plt.figure()" && \
	python -c "import mne; mne.set_config('MNE_USE_CUDA', 'false')" && \
	python -c "import mne; mne.set_config('MNE_LOGGING_LEVEL', 'info')" && \
	python -c "import mne; level = mne.get_config('MNE_LOGGING_LEVEL'); assert level.lower() == 'info', repr(level)" && \
	make test-doc

ENTRYPOINT $HOME/mne-python/start_services.sh && /bin/bash
