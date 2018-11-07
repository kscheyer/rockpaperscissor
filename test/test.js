var bn = require('bignumber.js');

Game = artifacts.require('./game.sol');

contract('testing rockpaperscissors', async (accounts) => {
	const WEI = 10**18;

	let wager = 1 * WEI;
	let owner = accounts[0];
	let game;

	let player1 = accounts[1];
	let player1Move = 'Paper';
	let player1Password = '123';

	let player2 = accounts[2];
	let player2Move = 'Rock';
	let player2Password = '456';

	it('deploy rockpaperscissors', async() => {
		game = await Game.new();
		assert.equal(await game.owner(), owner);
	});

	it('challenging a bastard', async() => {
		await game.challenge(player2, {from: player1, value: wager});
		let pairHash = await game.getPairHash(player1, player2);
		let gameStateCheck = await game.games(pairHash);
		assert.equal(gameStateCheck[0], wager);
		assert.equal(gameStateCheck[1], 1);
		console.log(gameStateCheck);
	});

	it('accept challenge', async() =>{
		await game.acceptChallenge(player1, {from: player2, value: wager});
		let pairHash = await game.getPairHash(player1, player2);
		let gameStateCheck = await game.games(pairHash);
		assert.equal(gameStateCheck[0], wager);
		assert.equal(gameStateCheck[1], 2);
	});

	it('player 1 plays', async() => {
		let secretMove = await game.GetHashedMove(player1Move, player1Password);

		await game.play(player2, secretMove, {from: player1});
		let pairHash = await game.getPairHash(player1, player2);
		let gameStateCheck = await game.games(pairHash);
		assert.equal(gameStateCheck[1], 3);
	});

	it('player 2 plays', async() => {
		let secretMove = await game.GetHashedMove(player2Move, player2Password);
		
		await game.play(player1, secretMove, {from: player2});
		let pairHash = await game.getPairHash(player1, player2);
		let gameStateCheck = await game.games(pairHash);
		assert.equal(gameStateCheck[1], 3);
	});

	it('player 1 finalizes move', async() => {
		let pairHash = await game.getPairHash(player1, player2);
		let gameStateCheck = await game.games(pairHash);

		await game.finalizeMove(player2, player1Move, player1Password, {from: player1});

		console.log(gameStateCheck[1]);
		assert.equal(gameStateCheck[1], 4);
		assert.equal(gameStateCheck[2][player1], keccak256(abi.encodePacked(player1Move)));
	});

	it ('player 2 finalizes move', async() => {
		let pairHash = await game.getPairHash(player1, player2);
		let gameStateCheck = await game.games(pairHash);

		await game.finalizeMove(player2, player1Move, player1Password, {from: player1});

		assert.equal(gameStateCheck[1], 0);
		assert.equal(gameStateCheck[2][player2], keccak256(abi.encodePacked(player2Move)));
	})
});

