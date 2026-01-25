if [[ -d "/opt/homebrew/bin" ]]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@11/11.0.25/libexec/openjdk.jdk/Contents/Home"

export _ZO_DATA_DIR="$HOME/Library/Application Support"
