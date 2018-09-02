var bn = require('bignumber.js');

Game = artifcats.require('./game.sol');

contract('testing rockpaperscissors', async (accounts) => {
	let owner = acoounts[0];
	let game;

	it('deploy rockpaperscissors', async() => {
		game = await Game.new();
		assert.equal(await game.owner(), owner);
	});
});

