for field in title author subject series identifier keyword
do
    target="${field}.sql"
    CMD="perl ~/Evergreen/Open-ILS/src/support-scripts/symspell-sideload.pl ${field}"
    echo "${CMD} ${target}"
    eval "$CMD" > "$target"
done
