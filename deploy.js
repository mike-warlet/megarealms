const hre = require("hardhat");
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying v2 com:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH\n");

  // 1. Deploy RealmToken v2
  console.log("=== 1. RealmToken v2 ($REALM) ===");
  const RealmToken = await hre.ethers.getContractFactory("RealmToken");
  const realm = await RealmToken.deploy();
  await realm.waitForDeployment();
  const realmAddr = await realm.getAddress();
  console.log("  RealmToken:", realmAddr);
  await sleep(3000);

  // 2. Deploy GoldExchange v2
  console.log("\n=== 2. GoldExchange v2 ===");
  const goldPerRealm = 1000;
  const GoldExchange = await hre.ethers.getContractFactory("GoldExchange");
  const exchange = await GoldExchange.deploy(realmAddr, goldPerRealm);
  await exchange.waitForDeployment();
  const exchangeAddr = await exchange.getAddress();
  console.log("  GoldExchange:", exchangeAddr);
  await sleep(3000);

  // 3. Deploy GameItems v2
  console.log("\n=== 3. GameItems v2 ===");
  const GameItems = await hre.ethers.getContractFactory("GameItems");
  const items = await GameItems.deploy();
  await items.waitForDeployment();
  const itemsAddr = await items.getAddress();
  console.log("  GameItems:", itemsAddr);
  await sleep(3000);

  // 4. Deploy GameCharacter v2
  console.log("\n=== 4. GameCharacter v2 ===");
  const GameCharacter = await hre.ethers.getContractFactory("GameCharacter");
  const chars = await GameCharacter.deploy();
  await chars.waitForDeployment();
  const charsAddr = await chars.getAddress();
  console.log("  GameCharacter:", charsAddr);
  await sleep(3000);

  // 5. Registrar itens
  console.log("\n=== 5. Registrando itens ===");
  const itens = [
    ["Club","weapon",3,0,0,20,false],
    ["Sword","weapon",8,0,0,100,false],
    ["Fire Sword","weapon",20,0,0,800,false],
    ["Magic Staff","weapon",14,0,0,500,false],
    ["Bow","weapon",10,0,0,300,false],
    ["Leather Armor","armor",0,3,0,80,false],
    ["Chain Armor","armor",0,6,0,250,false],
    ["Plate Armor","armor",0,12,0,900,false],
    ["Health Potion","potion",0,0,100,25,true],
    ["Mana Potion","potion",0,0,100,30,true],
    ["Dragon Scale","loot",0,0,0,100,true],
  ];
  for (const [n,t,a,d,h,p,s] of itens) {
    const tx = await items.registerItem(n,t,a,d,h,p,s);
    await tx.wait(2);
    await sleep(3000);
    console.log("  "+n+" OK");
  }

  // 6. Salvar enderecos
  const addresses = {
    realmToken: realmAddr,
    goldExchange: exchangeAddr,
    items: itemsAddr,
    characters: charsAddr,
    network: "base",
    chainId: 8453,
    goldPerRealm: goldPerRealm,
    deployer: deployer.address,
    version: "v2"
  };

  const fs = require("fs");
  fs.writeFileSync("addresses.json", JSON.stringify(addresses, null, 2));

  console.log("\n=== Deploy v2 completo! ===");
  console.log("  $REALM:", realmAddr);
  console.log("  GoldExchange:", exchangeAddr);
  console.log("  GameItems:", itemsAddr);
  console.log("  GameCharacter:", charsAddr);
  console.log("\nEnderecos salvos em addresses.json");
}

main().catch(e => { console.error(e); process.exitCode = 1; });
