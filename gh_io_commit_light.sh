#!/bin/sh

#From https://gohugo.io/hosting-and-deployment/hosting-on-github/#build-and-deployment

hugo
cd public && git add --all && git commit -m "Publishing to gh-pages" && cd ..
