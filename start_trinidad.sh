#!/usr/bin/env sh

jruby --server -J-Xmx2048m -J-Xms2048m -J-Xmn512m -S trinidad --threadsafe
