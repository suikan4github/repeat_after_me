FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# 必要な基本パッケージとJavaのインストール
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Android SDKの環境変数設定
ENV ANDROID_HOME=/usr/local/android-sdk
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Android Command-line Toolsのダウンロードと配置
ARG ANDROID_CMDLINE_TOOLS_VERSION=15859902
ARG ANDROID_CMDLINE_TOOLS_SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    curl --fail --location --show-error --silent \
      "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" \
      --output /tmp/commandlinetools.zip && \
    echo "${ANDROID_CMDLINE_TOOLS_SHA256}  /tmp/commandlinetools.zip" | sha256sum --check --status && \
    unzip /tmp/commandlinetools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm /tmp/commandlinetools.zip

# Android SDKライセンスの承諾と、必要なコンポーネントのインストール
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0" "ndk;27.0.12077973"

# Flutter SDKのインストール
ENV FLUTTER_HOME=/usr/local/flutter
RUN git clone --depth 1 --branch 3.32.8 https://github.com/flutter/flutter.git ${FLUTTER_HOME}
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter config --no-analytics --android-sdk ${ANDROID_HOME} && \
    flutter precache --android --web

WORKDIR /workspace
