pragma solidity 0.4.24;

contract game{
    
    struct Game {
        uint wager;
        GameState state;
        mapping(uint => bytes32) playerMove;
    }
    
    enum GameState { ready, challenged, accepted, playing, evaluating }
    enum EvalState {win, lose, draw}
    enum Players {player1, player2}
    
    mapping(bytes32 => Game) public games;
    mapping(address => uint) public moneys;
    mapping(bytes32 => mapping(bytes32 => EvalState)) public evulationMapping;
    address public owner;
    
    constructor()
    {
        owner = msg.sender;
        
        evulationMapping[keccak256("Paper")][keccak256("Rock")] = EvalState.win;
        evulationMapping[keccak256("Paper")][keccak256("Scissors")] = EvalState.lose;
        evulationMapping[keccak256("Paper")][keccak256("Paper")] = EvalState.draw;
        evulationMapping[keccak256("Rock")][keccak256("Rock")] = EvalState.draw;
        evulationMapping[keccak256("Rock")][keccak256("Scissors")] = EvalState.win;
        evulationMapping[keccak256("Rock")][keccak256("Paper")] = EvalState.lose;
        evulationMapping[keccak256("Scissors")][keccak256("Rock")] = EvalState.lose;
        evulationMapping[keccak256("Scissors")][keccak256("Scissors")] = EvalState.draw;
        evulationMapping[keccak256("Scissors")][keccak256("Paper")] = EvalState.win;
    }
    
    function challenge(address bastard)
    external
    payable
    {
        bytes32 gameHash = getPairHash(msg.sender, bastard);
        
        require(games[gameHash].state == GameState.ready);
        require(msg.value > 10 finney);
        
        games[gameHash].wager = msg.value;
        games[gameHash].state = GameState.challenged;
    }
    
    function acceptChallenge(address challenger)
    external
    payable
    {
        bytes32 gameHash = getPairHash(msg.sender, challenger);
        
        require(games[gameHash].state == GameState.challenged);
        require(msg.value == games[gameHash].wager);
        
        games[gameHash].state = GameState.accepted;
    }
    
    function play(address opponent, bytes32 secretMove)
    external
    {
        bytes32 gameHash = getPairHash(msg.sender, opponent);
        
        require(games[gameHash].state == GameState.accepted || games[gameHash].state == GameState.playing);
        games[gameHash].state = GameState.playing;
        
        if (opponent > msg.sender)
            SetPlayerMove(gameHash, Players.player1, secretMove);
        else
            SetPlayerMove(gameHash, Players.player2, secretMove);
    }
    
    function finalizeMove(address opponent, string move, string movePassword)
    external
    {
        bytes32 gameHash = getPairHash(msg.sender, opponent);
        
        require(
            GetPlayerMove(gameHash, Players.player1).length > 0 && 
            GetPlayerMove(gameHash, Players.player2).length > 0);// both players have made their move
        require(
            games[gameHash].state == GameState.playing || 
            games[gameHash].state == GameState.evaluating);
        
        bytes32 verifiedMove = keccak256(abi.encodePacked(move, movePassword));
        
        if (opponent > msg.sender) // Player1
        {
            require(verifiedMove == GetPlayerMove(gameHash, Players.player1));
            require(Evaluate(gameHash, Players.player1, move, msg.sender, opponent));            
            
        }
        else // Player2
        {            
            require(verifiedMove == GetPlayerMove(gameHash, Players.player2));
            require(Evaluate(gameHash, Players.player2, move, opponent, msg.sender));
        }
    }

    function cashOut()
    external
    {
        uint amount = moneys[msg.sender];
        delete moneys[msg.sender];
        msg.sender.transfer(amount);
    }
    
    function Evaluate(bytes32 gameHash, Players player, string move, address p1Address, address p2Address)
    internal
    returns (bool)
    {
            SetPlayerMove(gameHash, player, keccak256(abi.encodePacked(move)));
                
            if(games[gameHash].state == GameState.playing) // 1st to evaulate
            {
                games[gameHash].state = GameState.evaluating;
            }
            else // 2nd to evaluate
            {
                Payout(gameHash, p1Address, p2Address);
                games[gameHash].state = GameState.ready;
            }
            assert(games[gameHash].state != GameState.playing);
            return true;
    }
    
    function Payout(bytes32 gameHash, address p1Address, address p2Address)
    internal
    {
        if (evulationMapping[GetPlayerMove(gameHash, Players.player1)][GetPlayerMove(gameHash, Players.player2)] == EvalState.win)
        {
            moneys[p1Address] += games[gameHash].wager * 2;
        }
        else if (evulationMapping[GetPlayerMove(gameHash, Players.player1)][GetPlayerMove(gameHash, Players.player2)] == EvalState.lose)
        {
            moneys[p2Address] += games[gameHash].wager * 2;
        }
        else
        {
            moneys[p1Address] += (games[gameHash].wager * 90)/100;
            moneys[p2Address] += (games[gameHash].wager * 90)/100;
        }
            
    }
    
    function GetPlayerMove(bytes32 gameHash, Players player)
    public
    view
    returns (bytes32)
    {
        return games[gameHash].playerMove[uint(player)];
    }
    
    function SetPlayerMove(bytes32 gameHash, Players player, bytes32 move)
    internal
    {
        games[gameHash].playerMove[uint(player)] = move;
    }

    function GetHash(string s1)
    external
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(s1));
    }

    function GetHash(string s1, string s2)
    external
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(s1, s2));
    }
    
    function getPairHash(address _a, address _b)
    public
    pure
    returns (bytes32){
        return (_a < _b) ? keccak256(abi.encodePacked(_a, _b)) :  keccak256(abi.encodePacked(_b, _a));
    }
    
    function ()
    external
    payable
    {
        emit hello(msg.sender, msg.value);
    }
    
    event hello(address sender, uint amount);
    
}