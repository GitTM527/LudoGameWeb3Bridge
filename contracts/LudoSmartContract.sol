// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LudoSmartContract {
    // Total spots on the Ludo board
    uint8 public constant TOTAL_SPOTS = 52; 
    // The spot where a player wins
    uint8 public constant WINNING_SPOT = TOTAL_SPOTS; 
    
   
   
    struct Player {
        // Each player has 4 tokens
        uint8[4] tokens; 
        bool hasJoined;
    }

    // Store up to 4 players
    address[4] public players; 
    mapping(address => Player) public playerData;

    // Tracks whose turn it is
    uint8 public currentPlayerIndex; 
    bool public gameStarted;

    event DiceRolled(address indexed player, uint8 result);
    event PlayerMoved(address indexed player, uint8 tokenIndex, uint8 newPosition);
    event PlayerWon(address indexed player);

    
    
    // Modifier to ensure game has started
    modifier onlyWhenGameStarted() {
        require(gameStarted, "The game has not started yet.");
        _;
    }

    // Modifier to ensure it's the caller's turn
    modifier onlyCurrentPlayer() {
        require(players[currentPlayerIndex] == msg.sender, "It's not your turn.");
        _;
    }

    // Modifier to ensure only one of the four players can join
    modifier onlyBeforeGameStarted() {
        require(!gameStarted, "Game has already started.");
        _;
    }

    
    // Function for each time a new player joins the game (max 4 players)
    function joinGame() external onlyBeforeGameStarted {
        require(playerData[msg.sender].hasJoined == false, "You have already joined.");
        require(players[3] == address(0), "The game already has 4 players.");

        // Assign player to the next empty spot
        for (uint8 i = 0; i < 4; i++) {
            if (players[i] == address(0)) {
                players[i] = msg.sender;
                playerData[msg.sender].hasJoined = true;
                break;
            }
        }

        // Start the game if 4 players have joined
        if (players[3] != address(0)) {
            gameStarted = true;
        }
    }

    // Dice rolling function using blockhash as a source of pseudo-randomness
    function rollDice() public onlyWhenGameStarted onlyCurrentPlayer returns (uint8) {
        uint8 diceResult = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 6) + 1;
        emit DiceRolled(msg.sender, diceResult);
        return diceResult;
    }

    // Move a token forward based on the dice result
    function moveToken(uint8 tokenIndex) public onlyWhenGameStarted onlyCurrentPlayer {
        require(tokenIndex < 4, "Invalid token index.");

        uint8 diceResult = rollDice();
        uint8 currentPos = playerData[msg.sender].tokens[tokenIndex];
        uint8 newPos = currentPos + diceResult;

        if (newPos > WINNING_SPOT) {
            newPos = currentPos; // Token stays in place if it exceeds the final spot
        }

        playerData[msg.sender].tokens[tokenIndex] = newPos;

        emit PlayerMoved(msg.sender, tokenIndex, newPos);

        // Check if the player has won
        if (newPos == WINNING_SPOT) {
            emit PlayerWon(msg.sender);
        }

        // Pass the turn to the next player
        nextTurn();
    }

    // Advance the turn to the next player
    function nextTurn() internal {
        currentPlayerIndex = (currentPlayerIndex + 1) % 4;
    }
}
