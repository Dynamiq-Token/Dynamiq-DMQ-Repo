const { ethers } = require("hardhat");

async function main() {
    const deployer = new ethers.Wallet(process.env.DEPLOYER_PK, ethers.provider);
    const devWallet = new ethers.Wallet(process.env.DEVELOPER_PK, ethers.provider);
    const rewardsWallet = new ethers.Wallet(process.env.REWARDS_PK, ethers.provider);
    const marketingWallet = new ethers.Wallet(process.env.MARKETING_PK, ethers.provider);
    const liquidityWallet = new ethers.Wallet(process.env.LIQUIDITY_PK, ethers.provider);

    console.log(`Deploying contracts with the account: ${deployer.getAddress()}`);

    const DynamiqToken = await ethers.getContractFactory("DynamiqToken");
    const token = await DynamiqToken.deploy(
        devWallet.getAddress(),    
        "0x0000000000000000000000000000000000000000", 
        marketingWallet.getAddress(),
        rewardsWallet.getAddress(), 
        liquidityWallet.getAddress(), 
    );

    await token.waitForDeployment();  
    const tokenAddress = await token.getAddress();
    console.log(`DynamiqToken deployed at: ${tokenAddress}`);

    const Staking = await ethers.getContractFactory("Staking");
    const staking = await Staking.deploy(
        tokenAddress, 
        rewardsWallet.getAddress()
    );

    await staking.waitForDeployment();  
    const stakingAddress = await staking.getAddress();
    console.log(`Staking contract deployed at: ${stakingAddress}`);

    const tx = await token.setStakingContract(stakingAddress);
    await tx.wait();  

    console.log("Owner:", await deployer.getAddress());
    console.log("Dev Wallet:", await devWallet.getAddress());
    console.log("Marketing Wallet:", await marketingWallet.getAddress());
    console.log("Rewards Wallet:", await rewardsWallet.getAddress());
    console.log("Staking Contract:", stakingAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });