const hre = require("hardhat");

async function main() {
  // Get the deployed contract address - replace with your actual deployed address
  const NFT_CONTRACT_ADDRESS = "0xf037dddC941afB5705eaA367b6ccC741CA4379e6";
  
  console.log("Preparing to mint NFT...");

  // Get the contract instance
  const nftContract = await hre.ethers.getContractAt("NFT", NFT_CONTRACT_ADDRESS);
  
  // Get signer (your account)
  const [deployer] = await hre.ethers.getSigners();
  console.log(`Using account: ${deployer.address}`);
  
  // Create sample metadata for the NFT
  const basicMetadata = {
    uri: "https://picsum.photos/id/237/200/300",
    certificateType: "Achievement",
    userName: " ",
    title: "First Certificate",
    issuerName: "Certifera"
  };
  
  const detailsMetadata = {
    walletAddress: deployer.address,
    date: new Date().toISOString().split('T')[0], // Current date in YYYY-MM-DD format
    transfer: true,
    digitalSignature: "0xsignature123"
  };
  
  const statusMetadata = {
    request: true,
    verified: true,
    verifierAddress: deployer.address,
    requestAccepted: true
  };
  
  console.log("Minting NFT...");
  
  // Mint the NFT
  const mintTx = await nftContract.mintNFT(
    deployer.address, // recipient
    basicMetadata,
    detailsMetadata,
    statusMetadata
  );
  
  // Wait for transaction to be mined
  console.log("Transaction sent, waiting for confirmation...");
  const receipt = await mintTx.wait();
  
  // Get the minted token ID from events
  let tokenId;
  for (const event of receipt.logs) {
    try {
      const parsedLog = nftContract.interface.parseLog(event);
      if (parsedLog && parsedLog.name === "NFTMinted") {
        tokenId = parsedLog.args.tokenId;
        break;
      }
    } catch (e) {
      // Skip logs that can't be parsed
      continue;
    }
  }
  
  console.log(`NFT minted successfully! Token ID: ${tokenId}`);
  console.log(`Owner: ${deployer.address}`);
  
  // If you want to see the token's metadata
  console.log("Fetching token metadata...");
  const metadata = await nftContract.getTokenMetadata(tokenId);
  console.log("Token metadata:", metadata);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error minting NFT:", error);
    process.exit(1);
  });