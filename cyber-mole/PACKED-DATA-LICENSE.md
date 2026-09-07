# Altered Exomizer decoder

The SDK-owned hardware-loader decoder is an altered version of Web64's
adaptation of Exomizer 3.1.2 `exodecrs/exodecrunch.s`, commit
`ba91318e02bc0f69e437379a84348d416c4a19aa` from
https://bitbucket.org/magli143/exomizer.

This version adds input/output/history bounds and error unwinding, relocates scratch
and code, and specializes its supported stream contract to backward P39/M255.
It is not the original Exomizer source. Container validation, CRC and scratch-
before-commit installation are separate SDK code. District cache management
remains application code. The former private decoder copy has been removed.

Copyright (c) 2002-2020 Magnus Lind and contributors.

This software is provided 'as-is', without any express or implied warranty. In no event will
the authors be held liable for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any purpose, including commercial
applications, and to alter it and redistribute it freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim that you wrote
   the original software. An acknowledgment in product documentation is appreciated but not
   required.
2. Altered source versions must be plainly marked as such and must not be represented as the
   original software.
3. This notice may not be removed or altered from a source distribution.

The adapted 6502 decruncher also retains the upstream restriction that the Exomizer name and
copyright-holder names may not endorse derived products without prior written permission.
