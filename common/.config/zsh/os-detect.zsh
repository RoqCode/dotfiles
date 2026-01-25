if [[ -z "${DOT_OS:-}" ]]; then
  case "$(uname -s)" in
    Darwin) DOT_OS="mac" ;;
    Linux) DOT_OS="linux" ;;
    *) DOT_OS="unknown" ;;
  esac
  export DOT_OS
fi
