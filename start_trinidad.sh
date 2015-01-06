#!/usr/bin/env sh

jruby --server -S trinidad --threadsafe
# ulimit -n 16384; jruby --server -J-Xmx2048m -J-Xms1024m -J-Xmn512m -J-XX:MaxPermSize=512m -S trinidad -e production --threadsafe --config config/trinidad.yml
