#!/bin/zsh

set -euo pipefail

repository_root="${0:A:h:h}"
private_root="${repository_root}/PrivateGameProjects"
binary_root="${repository_root}/BinaryFrameworks"
build_root="${repository_root}/.build/PrivateGameFrameworks"
modules=(TicTacToeEngine SnakeEngine DropMergeEngine)

mkdir -p "${binary_root}" "${build_root}"

for module_name in "${modules[@]}"; do
  project_root="${private_root}/${module_name}"
  build_script="${project_root}/Scripts/build-xcframework.sh"
  if [[ ! -x "${build_script}" ]]; then
    echo "Missing private project or executable build script: ${build_script}" >&2
    exit 1
  fi

  module_build_root="${build_root}/${module_name}"
  "${build_script}" "${module_build_root}"

  destination="${binary_root}/${module_name}.xcframework"
  rm -rf "${destination}"
  ditto "${module_build_root}/${module_name}.xcframework" "${destination}"
done

ruby "${repository_root}/Scripts/verify-binary-frameworks.rb"
echo "Updated binary frameworks in ${binary_root}"
