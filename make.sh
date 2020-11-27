# v=$(grep "\"version\"" info.json | sed 's|.*:||;s|[",]||g;s| ||g')
# n=$(grep "\"name\"" info.json | sed 's|.*:||;s|[",]||g;s| ||g')
# #echo ${n}_${v}.zip

# powershell -c "\$files = Get-ChildItem -Path . -Exclude .git,*.sh
# Compress-Archive -Path \$files -DestinationPath ../${n}_${v}.zip"

v=$(grep "\"version\"" info.json | sed 's|.*:||;s|[",]||g;s| ||g')
n=$(grep "\"name\"" info.json | sed 's|.*:||;s|[",]||g;s| ||g')
echo ${n}_${v}.zip
cd ..

7z a -tzip ${n}_${v}.zip ./${n} -xr'!.git' -xr'!.gitignore' -xr'!*.pdn'