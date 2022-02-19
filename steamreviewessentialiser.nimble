# Package

version       = "0.1.0"
author        = "Akito <the@akito.ooo>"
description   = "Extract most used words from Steam reviews to create an aggregated list of most used keywords represented as a tag cloud."
license       = "GPL-3.0-or-later"
srcDir        = "src"
bin           = @["steamreviewessentialiser"]
skipDirs      = @["tasks"]
skipFiles     = @["README.md"]
skipExt       = @["nim"]


# Dependencies

requires "nim    >= 1.6.4"
requires "nimdbx >= 0.4.1"


# Tasks

task intro, "Initialize project. Run only once at first pull.":
  exec "git submodule add https://github.com/theAkito/nim-tools.git tasks || true"
  exec "git submodule update --init --recursive"
  exec "git submodule update --recursive --remote"
  exec "nimble configure"
task configure, "Configure project. Run whenever you continue contributing to this project.":
  exec "git fetch --all"
  exec "nimble check"
  exec "nimble --silent refresh"
  exec "nimble install --accept --depsOnly"
  exec "git status"
task fbuild, "Build project.":
  exec """nim c \
            --define:danger \
            --opt:speed \
            --out:steamreviewessentialiser \
            src/steamreviewessentialiser
       """
task dbuild, "Debug Build project.":
  exec """nim c \
            --define:debug:true \
            --debuginfo:on \
            --out:steamreviewessentialiser \
            src/steamreviewessentialiser
       """
task makecfg, "Create nim.cfg for optimized builds.":
  exec "nim tasks/cfg_optimized.nims"
task clean, "Removes nim.cfg.":
  exec "nim tasks/cfg_clean.nims"
