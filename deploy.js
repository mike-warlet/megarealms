const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying com:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH\n");

  // 1. Deploy RealmToken ($REALM) — ERC-20
  console.log("=== 1. RealmToken ($REALM) ===");
  const RealmToken = await hre.ethers.getContractFactory("RealmToken");
  const realm = await RealmToken.deploy();
  await realm.waitForDeployment();
  const realmAddr = await realm.getAddress();
  console.log("  RealmToken ($REALM):", realmAddr);
  console.log("  Max Supply:", hre.ethers.formatEther(await realm.maxSupply()), "REALM");
  console.log("  Treasury (deployer):", hre.ethers.formatEther(await realm.balanceOf(deployer.address)), "REALM");

  // 2. Deploy GoldExchange (REALM <-> Gold)
  console.log("\n=== 2. GoldExchange ===");
  const goldPerRealm = 1000; // 1 REALM = 1000 Gold
  const GoldExchange = await hre.ethers.getContractFactory("GoldExchange");
  const exchange = await GoldExchange.deploy(realmAddr, goldPerRealm);
  await exchange.waitForDeployment();
  const exchangeAddr = await exchange.getAddress();
  console.log("  GoldExchange:", exchangeAddr);
  console.log("  Rate: 1 REALM =", goldPerRealm, "Gold");

  // 3. Deploy GameItems (ERC-1155)
  console.log("\n=== 3. GameItems ===");
  const GameItems = await hre.ethers.getContractFactory("GameItems");
  const items = await GameItems.deploy();
  await items.waitForDeployment();
  const itemsAddr = await items.getAddress();
  console.log("  GameItems (NFTs):", itemsAddr);

  // 4. Deploy GameCharacter (ERC-721)
  console.log("\n=== 4. GameCharacter ===");
  const GameCharacter = await hre.ethers.getContractFactory("GameCharacter");
  const chars = await GameCharacter.deploy();
  await chars.waitForDeployment();
  const charsAddr = await chars.getAddress();
  console.log("  GameCharacter (NFT):", charsAddr);

  // 5. Registrar itens basicos no contrato de items
  console.log("\n=== 5. Registrando itens ===");
  const itemsToRegister = [
    ["Club", "weapon", 3, 0, 0, 20, false],
    ["Sword", "weapon", 8, 0, 0, 100, false],
    ["Fire Sword", "weapon", 20, 0, 0, 800, false],
    ["Magic Staff", "weapon", 14, 0, 0, 500, false],
    ["Bow", "weapon", 10, 0, 0, 300, false],
    ["Leather Armor", "armor", 0, 3, 0, 80, false],
    ["Chain Armor", "armor", 0, 6, 0, 250, false],
    ["Plate Armor", "armor", 0, 12, 0, 900, false],
    ["Health Potion", "potion", 0, 0, 100, 25, true],
    ["Mana Potion", "potion", 0, 0, 100, 30, true],
    ["Dragon Scale", "loot", 0, 0, 0, 100, true],
  ];

  for (const [name, type, atk, def, heal, price, stack] of itemsToRegister) {
    await items.registerItem(name, type, atk, def, heal, price, stack);
    console.log(`  Item registrado: ${name}`);
  }

  // 6. Salvar enderecos para o frontend
  const addresses = {
    realmToken: realmAddr,
    goldExchange: exchangeAddr,
    items: itemsAddr,
    characters: charsAddr,
    network: hre.network.name,
    chainId: hre.network.config.chainId || 31337,
    goldPerRealm: goldPerRealm,
    deployer: deployer.address,
  };

  const fs = require("fs");
  fs.writeFileSync("addresses.json", JSON.stringify(addresses, null, 2));

  console.log("\n=== Deploy completo! ===");
  console.log("Enderecos salvos em addresses.json");
  console.log("\nResumo:");
  console.log("  $REALM Token:", realmAddr);
  console.log("  GoldExchange:", exchangeAddr);
  console.log("  GameItems:", itemsAddr);
  console.log("  GameCharacter:", charsAddr);
  console.log("\nProximo passo: verificar contratos no BaseScan");
  console.log("  npx hardhat verify --network base", realmAddr);
  console.log("  npx hardhat verify --network base", exchangeAddr, realmAddr, goldPerRealm);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
