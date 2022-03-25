// migrations/3_deploy_upgradeable_box.js
const TransparentUpgradeableProxy = artifacts.require('TransparentUpgradeableProxy');
const ProxyAdmin = artifacts.require('ProxyAdmin');
const PlanetNFTs = artifacts.require('PlanetNFTs');
// const PlanetNFTsV2 = artifacts.require('PlanetNFTsV2');

module.exports = async function (deployer) {
    await deployer.deploy(PlanetNFTs);
    const planetNFTs = await deployer.deploy(PlanetNFTs);
    await deployer.deploy(ProxyAdmin);
    const proxyAdmin = await ProxyAdmin.deployed();
    await deployer.deploy(TransparentUpgradeableProxy, planetNFTs.address, proxyAdmin.address, []);
    const trans = await TransparentUpgradeableProxy.deployed();
    const proxyPlanet = await PlanetNFTs.at(trans.address);
    await proxyPlanet.initialize();
    // await deployer.deploy(PlanetNFTsV2);
    // const planetNFTsV2 = await PlanetNFTsV2.deployed();
    // await planetNFTsV2.initialize();
    // console.log(planetNFTsV2.address);
};
// Box logic v1
// 0x6C06639F40f9D30dEc81338725B43121B4E7574B

// logic v2
// 0x6F17f4B30515d3f7947b2987D87554898fad89D0

// proxy admin
// 0xeD51FfF995Af38581d006bd04FE9d1da95D13dA1

// trans
// 0x6B064278122fC35137904f6755D2Fbb74Dc0CD02
