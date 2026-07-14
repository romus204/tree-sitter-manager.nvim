vim.o.makeprg =
    [[make $* \| awk 'BEGIN { RS = "([ \t\n]\|\x1b\\[[0-9;]*m)" } { if (RT ~ /^[ \t\n]$/) { printf "\%s\%s", $0, RT; } else { printf "\%s", $0; } fflush(); }']]
vim.o.errorformat = "    %f:%l"
