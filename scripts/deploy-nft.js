const hre = require("hardhat");

async function main() {
  console.log("Deploying NFT contract to Polygon Amoy testnet...");

  // Get the contract factory
  const NFT = await hre.ethers.getContractFactory("NFT");
  
  // Deploy the contract
  const nft = await NFT.deploy();
  
  // Wait for deployment to be mined using ethers v6 style
  await nft.waitForDeployment();
  
  // Get the contract address using ethers v6 style
  const nftAddress = await nft.getAddress();
  
  console.log(`NFT contract deployed to: ${nftAddress}`);
  
  // Verify the contract on Polygonscan
  console.log("Waiting a bit before verification...");
  await new Promise(resolve => setTimeout(resolve, 30000)); // 30 seconds wait
  
  console.log("Starting verification process...");
  try {
    await hre.run("verify:verify", {
      address: nftAddress,
      constructorArguments: []
    });
    console.log("Contract verified successfully");
  } catch (error) {
    if (error.message.includes("already verified")) {
      console.log("Contract is already verified!");
    } else {
      console.error("Error verifying contract:", error);
    }
  }
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });