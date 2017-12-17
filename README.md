B9Lab-ETH17-RockPaperScissors
=============================

This is the Solidity-only solution to the RockPaperScissors problem presented at https://academy.b9lab.com/courses/course-v1:B9lab+ETH-17+2017-10/courseware/82c7df09b67c4f96818e0a32a59b6457/d5b4341029a249bdb438d5a87a9c5a94/ .

The code currently includes the "stretch goal" of allowing any two users to play. However, the code is subject to different sets of players choosing the same identifier for their game.

When testing, you can use a *multi-parameter*, Solidity-equivalent `keccak256` function in Truffle's console by doing ```const keccak256 = (...words) => web3.sha3(words.join(""));```.

This code is (C) Digital Contraptions Imaginarium Ltd. and released under the MIT licence.
