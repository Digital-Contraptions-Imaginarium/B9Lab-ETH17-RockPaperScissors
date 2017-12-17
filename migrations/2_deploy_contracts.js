// Alice "0x51030097f30621e59a1792579babfc8848e36da3"
// Bob   "0xcf4a36a183783438bece2985b921e8f544265992"
// Carol "0x1b7bd0b069309cae8aff3b382cc356432d6c96f6"

var RockPaperScissors = artifacts.require("./RockPaperScissors.sol");

module.exports = function(deployer) {
    deployer.deploy(
        RockPaperScissors,
        { "from": "0x1b7bd0b069309cae8aff3b382cc356432d6c96f6" } // Carol
    );
};
