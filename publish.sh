#!/bin/bash

dotnet publish -c Release --runtime win-x64 --framework netcoreapp3.1 -o ./deploy/win ./ChaoticSpaceMappersOfSplorr/ChaoticSpaceMappersOfSplorr.fsproj
dotnet publish -c Release --runtime osx-x64 --framework netcoreapp3.1 --self-contained true -o ./deploy/mac ./ChaoticSpaceMappersOfSplorr/ChaoticSpaceMappersOfSplorr.fsproj
dotnet publish -c Release --runtime linux-x64 --framework netcoreapp3.1 --self-contained true -o ./deploy/linux ./ChaoticSpaceMappersOfSplorr/ChaoticSpaceMappersOfSplorr.fsproj

rm ./deploy/win/*.pdb
rm ./deploy/mac/*.pdb
rm ./deploy/linux/*.pdb

rm ./deploy/*.zip
"C:\Program Files\7-Zip\7z" a -tzip ./deploy/csmos.zip ./deploy/win/*
"C:\Program Files\7-Zip\7z" a -tzip ./deploy/csmos-mac.zip ./deploy/mac/*
"C:\Program Files\7-Zip\7z" a -tzip ./deploy/csmos-linux.zip ./deploy/linux/*

