FROM ubuntu:22.04

ARG ANDROID_SDK_VERSION=commandlinetools-linux-11076708_latest.zip
ARG BUILD_TOOLS_VERSION=34.0.0
ARG PLATFORM_VERSION=34
ARG NDK_VERSION=26.3.11579264
ARG NODE_VERSION=20

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator

# ── System deps ───────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    curl wget unzip zip git \
    openjdk-17-jdk \
    asterisk \
    adb \
    usbutils \
    udev \
    python3 python3-pip \
    build-essential \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js ───────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs

# ── Android SDK ───────────────────────────────────────────────
RUN mkdir -p $ANDROID_HOME/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/${ANDROID_SDK_VERSION} -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools && \
    mv /tmp/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# ── Accept licenses & install SDK components ──────────────────
RUN yes | sdkmanager --licenses && \
    sdkmanager \
        "platform-tools" \
        "platforms;android-${PLATFORM_VERSION}" \
        "build-tools;${BUILD_TOOLS_VERSION}" \
        "ndk;${NDK_VERSION}"

# ── Android udev rules (for USB passthrough) ──────────────────
RUN wget -q https://raw.githubusercontent.com/M0Rf30/android-udev-rules/main/51-android.rules \
    -O /etc/udev/rules.d/51-android.rules && \
    chmod a+r /etc/udev/rules.d/51-android.rules

# ── Gradle cache dir ──────────────────────────────────────────
RUN mkdir -p /root/.gradle

# ── Flutter ───────────────────────────────────────────────────
ARG FLUTTER_VERSION=3.29.2

RUN git clone https://github.com/flutter/flutter.git \
    /opt/flutter --depth 1 --branch ${FLUTTER_VERSION}

ENV PATH=$PATH:/opt/flutter/bin

# Pre-download Flutter tool binaries + accept Android licenses
RUN flutter precache --android && \
    yes | flutter doctor --android-licenses || true

COPY asterisk/ /etc/asterisk/

EXPOSE 5060/udp 8088/tcp 10000-20000/udp

CMD ["/usr/sbin/asterisk", "-f", "-U", "root", "-vvv"]

WORKDIR /workspace