# "work" context bundle.
# 
{ pkgs, lib, dotsLocal, ... }:

{
  suites.network-tools = {
    rclone = true;
  };
}
