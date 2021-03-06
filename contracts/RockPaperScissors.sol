pragma solidity ^0.4.15;

import "./Owned.sol";
import "./Stoppable.sol";

contract RockPaperScissors is Owned, Stoppable {

	// TODO: enable refund if the other player hasn't played after a specified number of blocks.
	//       This is would also cater for the case where a player calculates the hash of her move
	//       wrong, or forgets her key.

	// TODO: the VM for the exam supports up to Solidity 0.4.15, but when moving
	//       to a more recent version change the constant functions into view /
	//       pure

	// For testing, these are "rock", "paper" and "scissors" keccak256'ed against keys
	// "foo" and "bar" respectively:
	// - rock
	//   0xffa463dcb1b4e9cfa53f7fe643d7a0ddad43a35afc9d9c38e1c5eecb0a67c67a
	//   0xb4fede9b7fe437d813a61ac0f8d5b5acd2a6a43c5c8e570893f4acf2b1e86b28
	// - paper
	//   0xc8e1f249c6309f8ada36ec6b5363a545016e3df00d161d66beecb2c50ffb6e6b
	//   0xf50e64f76374d525abc0316b966355cca3af4c1b19e42158b2f5f4f28fb7a71f
	// - scissors
	//   0x9df3c12242d05234f0a00fa75a10a1a985f0ec39cdccd01aacf0e2ff9971d64a
	//   0x3268cd076d6ef66e9a96bea092564a912ccb849dd65a8bc976027fe600f47a8b
	//

	// price of creating a game in Wei, per player, set by the contract owner
	uint public gameCreationCost;

	struct PlayerStatusStruct {
		// the player's move, encrypted vs some key chosen by the player
		bytes32 encryptedMove;
		// either of ROCK, PAPER or SCISSORS, after the reveal
		string move;
	}

	struct GameStruct {
		address player1;
		address player2;
		bool checkedForWinner;
		mapping(address => PlayerStatusStruct) players;
	}

    // Note: players refer to the game by a human readable name, but its
    // keccak256 is used for the mapping
	mapping(bytes32 => GameStruct) public games;

	// The players' balances, so that at some point they can withdraw (and pay
    // the gas for it)
	mapping(address => uint) public balances;

	event LogGameCreated(string gameName, address playerAddress);
	event LogPlayerDeclares(string gameName, address playerAddress);
	event LogPlayerReveals(string gameName, address playerAddress, string move);
	// winnerAddress is set to zero if the match is even
	event LogWinner(string gameName, address winnerAddress);
	event LogWithdrawal(address playerAddress, uint balance);

	function areStringsEqual(string s1, string s2)
		public
		constant
		returns(bool areEqual)
	{
		return(keccak256(s1) == keccak256(s2));
	}

    // Note: the cost of playing is set by the contract creator, but it may be
    // left to the player to decide.
	function RockPaperScissors(uint _gameCreationCost)
		public
	{
        // playing can't be free
		require(_gameCreationCost > 0);

		gameCreationCost = _gameCreationCost;
	}

	// returns true if the specified game is full
	function isGameFull(string _gameName)
		public
		constant // should be view
		returns(bool)
	{
		bytes32 _gameNameHash = keccak256(_gameName);
		return((games[_gameNameHash].player1 == address(0)) ||
		       (games[_gameNameHash].player2 == address(0)));
	}

	// returns true if msg.sender is one of the specified game's players
	function isPlayerKnown(string _gameName)
		public
		constant // should be view
		returns(bool)
	{
		return(games[keccak256(_gameName)].players[msg.sender].encryptedMove != 0x0);
	}

	// returns true if both players in a specified game have declared their
	// secret move
	function haveBothPlayersDeclared(string _gameName)
		public
		constant // should be view
		returns(bool)
	{
		bytes32 _gameNameHash = keccak256(_gameName);
		return((games[_gameNameHash].players[games[_gameNameHash].player1].encryptedMove != 0x0) &&
			   (games[_gameNameHash].players[games[_gameNameHash].player2].encryptedMove != 0x0));
	}

	// returns true if both players in a specified game have revealed their
	// move
	function haveBothPlayersRevealed(string _gameName)
		public
		constant // should be view
		returns(bool)
	{
		bytes32 _gameNameHash = keccak256(_gameName);
		return(!areStringsEqual(games[_gameNameHash].players[games[_gameNameHash].player1].move, "") &&
			   !areStringsEqual(games[_gameNameHash].players[games[_gameNameHash].player2].move, ""));
	}

	// returns true if the specified keccak256 corresponds to the keccak256
	// of "rock", "paper" or "scissors"
	function isAllowedMove(string _move)
		public
		constant // should be pure
		returns(bool)
	{
		return(areStringsEqual(_move, "rock") ||
		       areStringsEqual(_move, "paper") ||
		       areStringsEqual(_move, "scissors"));
	}

	// TODO: what if two different sets of players choose the same game name?
	// By calling the playerDeclares function, a player creates a new game or
	// joins a pre-existing one, and makes her payment. _encryptedMove is the
	// player's move, keccak256'ed vs a (yet unknown) key.
	function playerDeclares(string _gameName, bytes32 _encryptedMove)
		public
		payable
		onlyIfRunning
		returns(bool)
	{
		bytes32 _gameNameHash = keccak256(_gameName);

		// need to pay the right price
		require(msg.value == gameCreationCost);
		// can't join the game if two players have joined already
		require(!isGameFull(_gameName));
		// can't play vs yourself
		require(msg.sender != games[_gameNameHash].player1);

        // store the new player's address
		if(games[_gameNameHash].player1 == address(0)) {
			games[_gameNameHash].player1 = msg.sender;
			// this initialization is needed if the game name is recycled
	        games[_gameNameHash].checkedForWinner = false;
			LogGameCreated(_gameName, msg.sender);
		} else {
			games[_gameNameHash].player2 = msg.sender;
		}
        // save the encrypted move, for the reveal later
		games[_gameNameHash].players[msg.sender].encryptedMove = _encryptedMove;
		LogPlayerDeclares(_gameName, msg.sender);
		return true;
	}

	function playerReveals(string _gameName, string _move, string _key)
		public
		onlyIfRunning
		returns(bool)
	{
		bytes32 _gameNameHash = keccak256(_gameName);

		// the caller is one of the known players
		require(isPlayerKnown(_gameName));
        // the caller has not revealed already
        require(areStringsEqual(games[_gameNameHash].players[msg.sender].move, ""));
		// the player can't reveal her move until everybody has declared it
		// first
		// TODO: won't this waste the player's gas if she keeps trying? Do I
		//       need to care?
		require(haveBothPlayersDeclared(_gameName));
		// _move is one of "rock", "paper" and "scissors"
		require(isAllowedMove(_move));
		// the player has not cheated in declaring her original move
		require(games[_gameNameHash].players[msg.sender].encryptedMove == keccak256(_move, _key));

		games[_gameNameHash].players[msg.sender].move = _move;
		LogPlayerReveals(_gameName, msg.sender, _move);
		return(true);
	}

	// any of the two players can call this, to identify the winner and trigger
	// the assignment of the prize; note that this function does not do
	// the actual ether transfer, so not to penalise the loser with the gas
	// cost, if she is the caller
	function playerChecks(string _gameName)
		public
		onlyIfRunning
		returns(bool)
	{
		bytes32 _gameNameHash = keccak256(_gameName);

		// requires nobody to have checked for the winner yet
		require(!games[_gameNameHash].checkedForWinner);
		// the caller is actually one of the players
		require(isPlayerKnown(_gameName));
		// can't check for the winner until both players have revealed their move
		require(haveBothPlayersRevealed(_gameName));

		// prevents re-entry
		games[_gameNameHash].checkedForWinner = true;
		// does the actual check
		address theOtherPlayer = (msg.sender == games[_gameNameHash].player1) ?
			games[_gameNameHash].player2 : games[_gameNameHash].player1;
		bool even = areStringsEqual(games[_gameNameHash].players[msg.sender].move,
        	games[_gameNameHash].players[theOtherPlayer].move);
		address winner = (
			!even && // this is just to stop calculating immediately if even
			(areStringsEqual(games[_gameNameHash].players[msg.sender].move, "rock") &&
			 areStringsEqual(games[_gameNameHash].players[theOtherPlayer].move, "scissors")) ||
		 	(areStringsEqual(games[_gameNameHash].players[msg.sender].move, "paper") &&
 			 areStringsEqual(games[_gameNameHash].players[theOtherPlayer].move, "rock")) ||
		 	(areStringsEqual(games[_gameNameHash].players[msg.sender].move, "scissors") &&
 			 areStringsEqual(games[_gameNameHash].players[theOtherPlayer].move, "rock"))
		) ? msg.sender : theOtherPlayer;
		// makes the game name available again
		delete games[_gameNameHash];
		// assigns the prize, or returns the money if even
		balances[winner] += (even ? uint(1) : uint(2)) * gameCreationCost;
		balances[theOtherPlayer] += (even ? uint(1) : uint(0)) * gameCreationCost;
		LogWinner(_gameName, even ? address(0) : winner);
		return(true);
	}

	// Note, this function is intentionally not subject to the owner pausing
	// the instance.
	function withdraw()
		public
		returns(bool)
	{
		require(balances[msg.sender] > 0);

		uint balance = balances[msg.sender];
		balances[msg.sender] = 0;
		msg.sender.transfer(balance);
		LogWithdrawal(msg.sender, balance);
		return(true);
	}

}
