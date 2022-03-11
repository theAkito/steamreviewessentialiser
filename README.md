[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://nimble.directory/pkg/steamreviewessentialiser)

[![Source](https://img.shields.io/badge/project-source-2a2f33?style=plastic)](https://github.com/theAkito/steamreviewessentialiser)
[![Language](https://img.shields.io/badge/language-Nim-orange.svg?style=plastic)](https://nim-lang.org/)

![Last Commit](https://img.shields.io/github/last-commit/theAkito/steamreviewessentialiser?style=plastic)

[![GitHub](https://img.shields.io/badge/license-GPL--3.0-informational?style=plastic)](https://www.gnu.org/licenses/gpl-3.0.txt)
[![Liberapay patrons](https://img.shields.io/liberapay/patrons/Akito?style=plastic)](https://liberapay.com/Akito/)

## What
Fetches all reviews from a Steam game, then aggregates keywords found in them. Finally, the keywords are displayed in a tag cloud, where the most used keywords are shown biggest and the least used ones are shown smallest.
This way, you can get a first impression about a Steam game, within a minute of reading, instead of reading a couple reviews for 20 minutes, for example.

## Why
I like to read Steam reviews. Sometimes I do it, to quickly grasp what issues might arise from the game. For example, it's not fun to play a theoretically good game, which is in reality riddled with bugs.
So, if most negative reviews mention the word "bug" I can quickly see that word pointed out to me in the displayed tag cloud, when using this app.

## How
Work in Progress

## Where
Linux

## Goals
* Maintain Simplicity!

## Project Status
Alpha. Unstable API.

Server is working so far.
At this moment, retrieval of Tag Clouds via API of the server has to be concluded manually through API requests, by using cURL or similar HTTP clients.

## TODO
* ~~Save state, if review gathering was interrupted by program shutdown.~~
* ~~Use spell correction to correctly group similar or same words.~~
* ~~Maintain openness to variety of clients on different platforms.~~
* ~~Filter words like "is", "it", "that", "this", "these", "those"...~~
* ~~REST API~~

## License
Copyright © 2022  Akito <the@akito.ooo>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.