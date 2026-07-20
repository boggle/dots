# "work" context bundle.
# 
{ pkgs, lib, dotsLocal, ... }:

{
  suites.cloud-tools = {
    rclone = true;
    azure = true;
  };
}
