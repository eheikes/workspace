#
# Environment for software development.
#
FROM debian:testing

ENV USERNAME eheikes
ENV FULLNAME Eric Heikes
ENV EMAIL eheikes@gmail.com
ENV PASSWORD password1

#
# Replace shell with Bash so we can source files.
#
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

#
# Set debconf to run non-interactively.
#
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

#
# Install software.
#
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    autossh \
    ca-certificates \
    curl \
    dwdiff \
    emacs \
    git \
    htop \
    less \
    man-db \
    makepasswd \
    sudo \
    termit \
    traceroute \
    unattended-upgrades \
    wget \
    zsh

#
# Setup the environment.
#
RUN ln -sf /usr/share/zoneinfo/US/Central /etc/localtime

#
# Configure unattended upgrades.
#
RUN echo 'APT::Periodic::Update-Package-Lists "1";' >> /etc/apt/apt.conf.d/10periodic
RUN echo 'APT::Periodic::Download-Upgradeable-Packages "1";' >> /etc/apt/apt.conf.d/10periodic
RUN echo 'APT::Periodic::AutocleanInterval "7";' >> /etc/apt/apt.conf.d/10periodic
RUN echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/10periodic

#
# Setup the user.
#
RUN adduser --shell /usr/bin/zsh --disabled-login --gecos "$FULLNAME" $USERNAME
RUN usermod -p `echo "$PASSWORD" | makepasswd --clearfrom=- --crypt-md5 | awk '{ print $2 }'` $USERNAME
RUN chage -d 0 $USERNAME
RUN usermod -aG sudo $USERNAME

#
# Switch to the user & home directory.
#
USER $USERNAME
WORKDIR /home/$USERNAME

#
# Setup ~/bin
#
RUN mkdir -p ~/bin

#
# Install oh-my-zsh.
#
RUN git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh && \
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
RUN mkdir -p ~/.oh-my-zsh/plugins/git-eheikes && \
    wget --quiet https://gist.githubusercontent.com/eheikes/fd1cae80e91538d9928f/raw/4aee260f122dff1baac90808e85128ea0c8e69de/git-custom.sh -O ~/.oh-my-zsh/plugins/git-eheikes/git-eheikes.plugin.zsh
RUN sed -i 's/^plugins=\(.*\)/plugins=(extract git git-eheikes frontend-search node npm screen)/' ~/.zshrc

#
# Install hub.
#
RUN wget --quiet https://github.com/github/hub/releases/download/v2.2.1/hub-linux-amd64-2.2.1.tar.gz -O hub.tar.gz && \
    tar -zxf hub.tar.gz && \
    mv hub-linux-amd64-2.2.1/hub ~/bin/ && \
    rm -rf hub-linux-amd64-2.2.1 hub.tar.gz

#
# Install nvm and node tools.
#
ENV NVM_DIR /home/$USERNAME/.nvm
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.25.4/install.sh | PROFILE=~/.zshrc bash && \
    source $NVM_DIR/nvm.sh && \
    nvm install stable && \
    nvm alias default stable && \
    nvm use default && \
    npm install -g bower grunt-cli gulp yo

#
# Generate SSH keys.
#
RUN ssh-keygen -t rsa -b 4096 -C "eheikes@gmail.com" -N "" -f ~/.ssh/github.key
RUN ssh-keygen -t rsa -b 4096 -C "eheikes@gmail.com" -N "" -f ~/.ssh/bitbucket.key

#
# Various configuration.
#
RUN curl -fsSL https://gist.githubusercontent.com/eheikes/8e7503036072b719c2e6/raw/1db0de2993ef06348a5121ffdd3101934742f2b8/.emacs -o .emacs
RUN curl -fsSL https://gist.githubusercontent.com/eheikes/60354456e5a81150a2c8/raw/596b1217b0a7e1f3a9529cd14c16e03f94614186/.zshrc >> .zshrc
RUN git config --global user.name "$FULLNAME"
RUN git config --global user.email "$EMAIL"

ENTRYPOINT ["/usr/bin/zsh"]
