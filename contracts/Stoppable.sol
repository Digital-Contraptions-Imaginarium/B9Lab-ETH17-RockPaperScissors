pragma solidity ^0.4.15;

import "./Owned.sol";

contract Stoppable is Owned {

    bool public stopped;

    event LogStop(address requester);
    event LogReprise(address requester);

    modifier onlyIfRunning { require(!stopped); _; }
    modifier onlyIfStopped { require(stopped); _; }

    function Stoppable() public { }

    function stop()
        public
        onlyOwner
        onlyIfRunning
        returns(bool success)
    {
        stopped = true;
        LogStop(msg.sender);
        return(true);
    }

    function restart()
        public
        onlyOwner
        onlyIfStopped
        returns(bool success)
    {
        stopped = false;
        LogReprise(msg.sender);
        return(true);
    }

}
