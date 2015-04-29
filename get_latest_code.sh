#!/bin/bash
set -e
set -u

mirror_dir="${1}"
git_dir="${2}"

found_sort=0
for sort in sort gsort ; do
    if ${sort} --version-sort < /dev/null > /dev/null 2> /dev/null; then
        found_sort=1
        break
    fi
done

if [ ${found_sort} -ne 1 ] ; then
    echo "No suitable sort found. Must support --version-sort" >> /dev/stderr
    exit 1
fi

mkdir -p "${mirror_dir}"
mkdir -p "${git_dir}"

pushd "${mirror_dir}" > /dev/null
wget --mirror --no-parent -A '*.tar.gz' http://www.opensource.apple.com/tarballs/xnu/
popd > /dev/null

pushd "${git_dir}" > /dev/null
git init .
for file in $(ls "${mirror_dir}"/www.opensource.apple.com/tarballs/xnu/*.tar.gz | ${sort} -t- --version-sort -k2,2) ; do
    bname="$(basename ${file} .tar.gz)";
    version="${bname#xnu-}"
    commit_message="version ${version}"

    test "$(git log --oneline --grep "${commit_message}" --fixed-strings | wc -l)" -eq 0 || continue

    tar -C /tmp -x -z -f "${file}" "${bname}"
    rsync -a -v -z --delete --exclude .git "/tmp/${bname}/" .
    rm -r "/tmp/${bname}"
    git add -A
    git commit -m "version ${version}"
done
popd > /dev/null
