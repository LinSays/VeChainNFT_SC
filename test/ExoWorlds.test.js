const { assert, expect } = require("chai");
const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;
// advanceBlockTo
const TransparentUpgradeableProxy = artifacts.require('TransparentUpgradeableProxy');
const ProxyAdmin = artifacts.require('ProxyAdmin');
const PlanetNFTs = artifacts.require('PlanetNFTs');

// improve testing using https://github.com/AnAllergyToAnalogy/ERC721/blob/master/tests/Token.test.js

contract("PlanetNFTs unit tests", async (accounts) => {
    let planetNFTs, trans;
    const [minter, alice, bob] = accounts;

    beforeEach(async () => {
        trans = await TransparentUpgradeableProxy.deployed();
        planetNFTs = await PlanetNFTs.at(trans.address);
    });

    describe("Deployment", () => {
        it("contract has an address", async () => {
            const address = await planetNFTs.address;
            assert.notEqual(address, 0x0);
            assert.notEqual(address, "");
            assert.notEqual(address, null);
            assert.notEqual(address, undefined);
        });
        it("support name", async () => {
            const name = await planetNFTs.name.call();
            assert.equal(name, "PLANET");
        });
        it("support symbol", async () => {
            const symbol = await planetNFTs.symbol.call();
            assert.equal(symbol, "PLN");
        });
        it("support MaxLimit", async () => {
            const maxLimit = await planetNFTs.getMaxLimit();
            assert.equal(maxLimit, 10000);
        })
        it("support MaxPendingMintsToProces", async () => {
            const maxPendingMintsToProces = await planetNFTs.getMaxPendingMintsToProces();
            assert.equal(maxPendingMintsToProces, 100);
        })
        it("support oracleRandom", async () => {
            const oracleRandom = await planetNFTs.getOracleRandom();
            assert.equal(oracleRandom, ZERO_ADDRESS);
        })
        describe('init variables', () => {

            describe("Support Giveaway Address", () => {
                it("minter can set giveawayAddress", async () => {
                    await planetNFTs.setGiveAwayAddress(alice, { from: minter });
                    expect(await planetNFTs.getGiveAwayAddress()).to.equal(alice);
                })
                it("other account can't set giveawayAddress", async () => {
                    await expectRevert(
                        planetNFTs.setGiveAwayAddress(alice, { from: alice }),
                        "Ownable: caller is not the owner -- Reason given: Ownable: caller is not the owner.",
                    );
                })
            })
            describe("Support TotalMintsForGiveaway", () => {
                it("minter can set totalMintsForGiveaway", async () => {
                    await planetNFTs.setTotalMintsForGiveaway(10, { from: minter });
                    assert.equal((await planetNFTs.getTotalMintsForGiveaway()).toString(), '10');
                })
                it("other account can't set totalMintsForGiveaway", async () => {
                    await expectRevert(
                        planetNFTs.setTotalMintsForGiveaway(10, { from: alice }),
                        "Ownable: caller is not the owner -- Reason given: Ownable: caller is not the owner.",
                    );
                })
            })
        })
    });

    // describe("Mint batch", () => {
    //     before(async () => {
    //         await planetNFTs.setMaxLimit(200, { from: minter });
    //         await planetNFTs.initTokenList({ from: minter });
    //     })
    //     it("init available Tokens", async () => {
    //         assert.equal((await planetNFTs.getMaxLimit()).toString(), '200');
    //         assert.equal((await planetNFTs.availableTokenLength()).toString(), 200);
    //     });
    //     it("mint batch with giveaway address", async () => {
    //         assert.equal(await planetNFTs.getMaxLimit(), 200);
    //         await planetNFTs.setGiveAwayAddress(alice, { from: minter });
    //         // set total giveaway mint count
    //         await planetNFTs.setTotalMintsForGiveaway(10, { from: minter });
    //         const receipt = await planetNFTs.startMintBatch(4, { from: alice });
    //         assert.equal((await planetNFTs.getTotalMintsForGiveaway()).toString(), '6');
    //         expectEvent(receipt, "addPendingMint", { from: alice });
    //         const pendingMints = await planetNFTs.getPendingId();
    //         console.log(pendingMints);
    //         assert.equal(pendingMints, [1, 2, 3, 4]);
    //     })
    // });

    describe("pausing", () => {
        it("minter can pause", async () => {
            const receipt = await planetNFTs.pause({ from: minter });
            expectEvent(receipt, "Paused", { account: minter });

            assert.equal(await planetNFTs.paused(), true);
        });

        it("minter can unpause", async () => {
            const receipt = await planetNFTs.unpause({ from: minter });
            expectEvent(receipt, "Unpaused", { account: minter });

            assert.equal(await planetNFTs.paused(), false);
        });

        it("cannot mint while paused", async () => {
            await planetNFTs.pause({ from: minter });
            await expectRevert(
                planetNFTs.safeMint(alice, 0, { from: minter }),
                "Pausable: paused",
            );
        });

        it("other accounts cannot pause", async () => {
            await planetNFTs.unpause({ from: minter });

            await expectRevert(
                planetNFTs.pause({ from: alice }),
                "Ownable: caller is not the owner",
            );
        });

        it("other accounts cannot unpause", async () => {
            await planetNFTs.pause({ from: minter });
            await expectRevert(
                planetNFTs.unpause({ from: alice }),
                "Ownable: caller is not the owner",
            );
            await planetNFTs.unpause({ from: minter });
        });
    });

    describe("burning", () => {
        it("owner can burn their tokens", async () => {
            const tokenId = new BN("0");
            await planetNFTs.safeMint(alice, tokenId, { from: minter });
            const receipt = await planetNFTs.burn(tokenId, { from: minter });

            expectEvent(receipt, "Transfer", { from: alice, to: ZERO_ADDRESS, tokenId });

            assert.equal(await planetNFTs.balanceOf(alice), 0);
            assert.equal(await planetNFTs.totalSupply(), 0);
        });
        it("holders and others cann't burn their tokens", async () => {
            const tokenId = new BN("0");
            await planetNFTs.safeMint(alice, tokenId, { from: minter });

            expectRevert(planetNFTs.burn(tokenId, { from: alice }), "Ownable: caller is not the owner");
            expectRevert(planetNFTs.burn(tokenId, { from: bob }), "Ownable: caller is not the owner");
        });
    });

    describe("royalty", () => {
        it("set default royalty", async () => {
            await planetNFTs.setDefaultRoyalty(alice, 1000, { from: minter });
            const { 0: receiver, 1: royalty } = await planetNFTs.royaltyInfo(0, 1000);
            assert.equal(receiver, alice);
            assert.equal(royalty, 100);
        })
        it("set token royalty", async () => {
            await planetNFTs.setTokenRoyalty(0, bob, 2000, { from: alice });
            const { 0: receiver, 1: royalty } = await planetNFTs.royaltyInfo(0, 1000);
            assert.equal(receiver, bob);
            assert.equal(royalty, 200);
        })
    })
})
