pragma solidity ^0.4.15;

contract Owned {

    address public owner;

    event LogNewOwner(address oldOwner, address newOwner);

    modifier onlyOwner { require(msg.sender == owner); _; }

    function Owned()
        public
    {
        owner = msg.sender;
    }

    function changeOwner(address newOwner)
        public
        onlyOwner
        returns(bool)
    {
        LogNewOwner(owner, newOwner);
        owner = msg.sender;
        return(true);
    }

}
