const hre = require("hardhat");

// V2 contract addresses (already deployed on Base)
const REALM_TOKEN = "0xBA2cA14375b2cECA4f04350Bd014B375Bc014ad2";
const GOLD_EXCHANGE = "0x87eeF242A5DF7Bc22FEA46F93186CA7180B777CD";

// MegaRealms project treasury (receives 40% of inflation share)
const MEGAREALMS_TREASURY = "0xd1D211831672a9231f96792471688BF6dAA63C17"; // deployer wallet

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying RealmDAO with:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH");

  // ─── Phase 1: Deploy RealmDAO ──────────────────────────
  console.log("\n--- Phase 1: Deploy RealmDAO ---");
  const RealmDAO = await hre.ethers.getContractFactory("RealmDAO");
  const dao = await RealmDAO.deploy(REALM_TOKEN, GOLD_EXCHANGE);
  await dao.waitForDeployment();
  const daoAddr = await dao.getAddress();
  console.log("RealmDAO deployed at:", daoAddr);
  await sleep(3000);

  // ─── Phase 2: Configure RealmToken ─────────────────────
  console.log("\n--- Phase 2: Add DAO as minter + transfer ownership ---");
  const realmToken = await hre.ethers.getContractAt("RealmToken", REALM_TOKEN);

  // Add DAO as minter
  let tx = await realmToken.addMinter(daoAddr);
  await tx.wait(2);
  console.log("DAO added as minter on RealmToken");
  await sleep(3000);

  // Transfer RealmToken ownership to DAO
  tx = await realmToken.transferOwnership(daoAddr);
  await tx.wait(2);
  console.log("RealmToken ownership transferred to DAO");
  await sleep(3000);

  // ─── Phase 3: Transfer GoldExchange ownership ──────────
  console.log("\n--- Phase 3: Transfer GoldExchange ownership ---");
  const goldExchange = await hre.ethers.getContractAt("GoldExchange", GOLD_EXCHANGE);

  tx = await goldExchange.transferOwnership(daoAddr);
  await tx.wait(2);
  console.log("GoldExchange ownership transferred to DAO");
  await sleep(3000);

  // ─── Phase 4: Register MegaRealms as first project ────
  console.log("\n--- Phase 4: Register MegaRealms project ---");
  // Encode proposal data for ADD_PROJECT
  // Bootstrap: register MegaRealms as first project (guardian only, one-time)
  tx = await dao.bootstrapProject("MegaRealms", MEGAREALMS_TREASURY, 10000);
  await tx.wait(2);
  console.log("MegaRealms registered as first project (100% allocation)");
  await sleep(3000);

  // ─── Summary ───────────────────────────────────────────
  console.log("\n========================================");
  console.log("  DEPLOYMENT COMPLETE");
  console.log("========================================");
  console.log("RealmDAO:     ", daoAddr);
  console.log("RealmToken:   ", REALM_TOKEN, "(owner: DAO)");
  console.log("GoldExchange: ", GOLD_EXCHANGE, "(owner: DAO)");
  console.log("Guardian:     ", deployer.address);
  console.log("========================================");

  // Save addresses
  const fs = require("fs");
  const addresses = {
    RealmDAO: daoAddr,
    RealmToken: REALM_TOKEN,
    GoldExchange: GOLD_EXCHANGE,
    GameItems: "0x38536f96Cd4379A0C7cdAE5f57Bc115B49163e6e",
    GameCharacter: "0xEaE8Cd541D6E059A0E02208af0E22AefFAC07f26",
    guardian: deployer.address,
    network: "base",
    deployedAt: new Date().toISOString()
  };
  fs.writeFileSync("addresses-dao.json", JSON.stringify(addresses, null, 2));
  console.log("\nAddresses saved to addresses-dao.json");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
