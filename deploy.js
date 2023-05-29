async function main() {
  [owner] = await ethers.getSigners();

  const Staking = await ethers.getContractFactory('Staking', owner);

  const staking = await Staking.deploy(
    187848,
    {
      value: ethers.utils.parseEther('100')
    }
  );

  const Chainlink = await ethers.getContractFactory('Chainlink', owner);            chainlink = await Chainlink.deploy();
  const Tether = await ethers.getContractFactory('Tether', owner);                  tether = await Tether.deploy();
  const UsdCoin = await ethers.getContractFactory('UsdCoin', owner);                usdCoin = await UsdCoin.deploy();

  await staking.connect(owner).addToken('Chainlink',     'LINK', chainlink.address, 867, 1500);
  await staking.connect(owner).addToken('Tether',        'USDT', tether.address, 100, 200);
  await staking.connect(owner).addToken('UsdCoin',       'USDC', usdCoin.address, 100, 200, );

  console.log("Staking:",        staking.address);
  console.log("Chainlink:",      chainlink.address);
  console.log("Tether:",         tether.address);
  console.log("UsdCoin:",        usdCoin.address);

  await chainlink.connect(owner).approve(staking.address, ethers.utils.parseEther('100'));
  await staking.connect(owner).stakeTokens('LINK',ethers.utils.parseEther('100'))



  const provider = waffle.provider;
  const block = await provider.getBlock()
  const newCreatedDate = block.timestamp - (86400 * 365)
}

// npx hardhat run --network localhost scripts/deploy.js

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
